import Foundation

import StreamReader
import SystemPackage

import CMacroExports
import SignalHandling
import Utils



extension Process {
	
	/**
	How to redirect stdout and stderr? */
	public enum RedirectMode {
		case none
		case toNull
		case capture
		case toFd(FileDescriptor)
	}
	
	/**
	Spawns a process, and streams all of its outputs (stdout, stderr and all
	additional output file descriptors) in the handler (line by line, each line
	containing the newline char, a valid newline is only "\n", but line might not
	end with a newline if last line of the output).
	
	The process will be launched in its own PGID. Which means, if your process is
	launched in a Terminal, then you spawn a process using this method, then the
	user types Ctrl-C, your process will be killed, but the process you launched
	won’t be.
	
	However, you have an option to forward some signals to the processes you
	spawn using this method.
	
	IMHO the signal forwarding method, though a bit more complex (in this case, a
	lot of the complexity is hidden by this method), is better than using the
	same PGID than the parent for the child. In a shell, if a long running
	process is launched from a bash script, and said bash script is killed using
	a signal (but from another process sending a signal, not from the tty), the
	child won’t be killed! Using signal forwarding, it will.
	
	Some interesting links:
	- [The TTY demystified](http://www.linusakesson.net/programming/tty/)
	- [SIGTTIN / SIGTTOU Deep Dive](http://curiousthing.org/sigttin-sigttou-deep-dive-linux)
	- [Swift Process class source code](https://github.com/apple/swift-corelibs-foundation/blob/swift-5.3.3-RELEASE/Sources/Foundation/Process.swift)
	
	A dummy § for Xcode.
	
	- Important: For technical reasons (and design choice), if file descriptors
	to send is not empty, the process will be launched _via_ `xct`.
	
	- Note: We use `Process` to spawn the process. This is why the process is
	launched in its own PGID and why we have to use `xct` to launch it to be able
	to pass other file descriptors than stdin/stdout/stderr to it.
	
	One day we might rewrite this function using `posix_spawn` directly…
	
	- Note: On Linux, the PGID stuff is not true up to Swift 5.3.3 (currently in
	production!) It is true on the `main` branch though (2021-04-01).
	
	- Important: The handler will not be called on the calling thread (so you can
	`waitUntilExit` on the `Process` and still receive the stream “live”).
	
	- Parameter fileDescriptorsToSend: The file descriptors (other than `stdin`,
	`stdout` and `stderr`, which are handled and differently) to clone in the
	child process. The **value** is the file descriptor to clone (from the parent
	process to the child), the key is the descriptor you’ll get in the child
	process.
	- Parameter additionalOutputFileDescriptors: Additional output file
	descriptors to stream from the process. Usually used with
	`fileDescriptorsToSend` (you open a socket, give the write fd in fds to
	clone, and the read fd to additional output fds).
	- Returns: The _started_ `Process` object that was created and a dispatch
	group you can wait on to be sure the end of the streams was reached. */
	public static func spawnedAndStreamedProcess(
		_ executable: String, args: [String] = [],
		stdin: FileDescriptor? = FileDescriptor.xctStdin,
		stdoutRedirect: RedirectMode = RedirectMode.none,
		stderrRedirect: RedirectMode = RedirectMode.none,
		fileDescriptorsToSend: [FileDescriptor /* Value in **child** */: FileDescriptor /* Value in **parent** */] = [:],
		additionalOutputFileDescriptors: Set<FileDescriptor> = [],
		signalsToForward: Set<Signal> = Signal.toForwardToSubprocesses,
		outputHandler: @escaping (_ line: String, _ sourceFd: FileDescriptor) -> Void
	) throws -> (Process, DispatchGroup) {
		let p = Process()
		
		var fdRedirects = [FileDescriptor: FileDescriptor]()
		var outputFileDescriptors = additionalOutputFileDescriptors
		switch stdoutRedirect {
			case .none:         (/*nop*/)
			case .toNull:       p.standardOutput = nil
			case .toFd(let fd): p.standardOutput = FileHandle(fileDescriptor: fd.rawValue)
			case .capture:
				let pipe = Pipe()
				p.standardOutput = pipe
				let fd = FileDescriptor(rawValue: pipe.fileHandleForReading.fileDescriptor)
				let (inserted, _) = outputFileDescriptors.insert(fd); assert(inserted)
				fdRedirects[fd] = FileDescriptor.xctStdout
		}
		switch stderrRedirect {
			case .none:         (/*nop*/)
			case .toNull:       p.standardError = nil
			case .toFd(let fd): p.standardError = FileHandle(fileDescriptor: fd.rawValue)
			case .capture:
				let pipe = Pipe()
				p.standardError = pipe
				let fd = FileDescriptor(rawValue: pipe.fileHandleForReading.fileDescriptor)
				let (inserted, _) = outputFileDescriptors.insert(fd); assert(inserted)
				fdRedirects[fd] = FileDescriptor.xctStderr
		}
		
		let fdToSendFds: FileDescriptor?
		/* We will modify it later to add stdin if needed */
		var fileDescriptorsToSend = fileDescriptorsToSend
		
		if fileDescriptorsToSend.isEmpty {
			p.standardInput = stdin.flatMap{ FileHandle(fileDescriptor: $0.rawValue) }
			p.executableURL = URL(fileURLWithPath: executable)
			p.arguments = args
			fdToSendFds = nil
		} else {
			guard let execBaseURL = getenv(LibXctConstants.envVarNameExecPath).flatMap({ URL(fileURLWithPath: String(cString: $0)) }) else {
				LibXctConfig.logger?.error("Cannot launch process and send its fd if \(LibXctConstants.envVarNameExecPath) is not set.")
				throw LibXctError.envVarXctExecPathNotSet
			}
			/* The socket to send the fd. The tuple thingy _should_ be _in effect_
			 * equivalent to the C version `int sv[2] = {-1, -1};`.
			 * https://forums.swift.org/t/guarantee-in-memory-tuple-layout-or-dont/40122
			 * Stride and alignment should be the equal for CInt. */
			var sv: (CInt, CInt) = (-1, -1)
			guard socketpair(/*domain: */AF_UNIX, /*type: */SOCK_DGRAM, /*protocol: */0, /*socket_vector: */&sv.0) == 0 else {
				/* TODO: Throw a more informative error? */
				throw LibXctError.systemError(Errno(rawValue: errno))
			}
			
			p.executableURL = execBaseURL.appendingPathComponent("xct")
			p.arguments = ["internal-fd-get-launcher", executable] + args
			p.standardInput = FileHandle(fileDescriptor: sv.1)
			fdToSendFds = FileDescriptor(rawValue: sv.0)
			
			if fileDescriptorsToSend[FileDescriptor.xctStdin] == nil {
				/* We must add stdin in the list of file descriptors to send. */
				fileDescriptorsToSend[FileDescriptor.xctStdin] = FileDescriptor.xctStdin
			}
		}
		
		let delayedSigations = try SigactionDelayer_Unsig.registerDelayedSigactions(signalsToForward, handler: { (signal, handler) in
			LibXctConfig.logger?.debug("Handler action in Process+Utils", metadata: ["signal": "\(signal)"])
			defer {handler(true)}
			
			guard p.isRunning else {return}
			kill(p.processIdentifier, signal.rawValue)
		})
		
		let streamGroup = DispatchGroup()
		var readSources = [DispatchSourceRead]()
		let streamQueue = DispatchQueue(label: "com.xcode-actions.spawn-and-stream")
		for fd in outputFileDescriptors {
			try setRequireNonBlockingIO(on: fd, logChange: additionalOutputFileDescriptors.contains(fd))
			
			let streamReader = FileDescriptorReader(stream: fd, bufferSize: 1024, bufferSizeIncrement: 512)
			streamReader.underlyingStreamReadSizeLimit = 0
			
			let streamSource = DispatchSource.makeReadSource(fileDescriptor: fd.rawValue, queue: streamQueue)
			readSources.append(streamSource)
			
			streamSource.setRegistrationHandler(handler: streamGroup.enter)
			streamSource.setCancelHandler(handler: streamGroup.leave)
			
			let timerRef = Ref<DispatchSourceTimer?>(nil)
			streamSource.setEventHandler{
				/* `source.data`: see doc of dispatch_source_get_data in objc */
				/* `source.mask`: see doc of dispatch_source_get_mask in objc (is always 0 for read source) */
				Process.handleProcessOutput(
					streamSource: streamSource,
					streamQueue: streamQueue,
					outputHandler: { str in outputHandler(str, fdRedirects[fd] ?? fd) },
					streamReader: streamReader,
					estimatedBytesAvailable: streamSource.data,
					timerRef: timerRef, fromTimer: false
				)
			}
		}
		
		readSources.forEach{ $0.activate() }
		
		#warning("TODO")
		p.terminationHandler = { _ in
			readSources.forEach{ $0.cancel() }
			let errors = SigactionDelayer_Unsig.unregisterDelayedSigactions(Set(delayedSigations.values))
			for (signal, error) in errors {
				LibXctConfig.logger?.error("Cannot unregister delayed sigaction: \(error)", metadata: ["signal": "\(signal)"])
			}
			/* Close fd to send fds if needed, and maybe others */
		}
		
		LibXctConfig.logger?.info("Launching process \(executable)\(fileDescriptorsToSend.isEmpty ? "" : " through xct")")
		do {
			try p.run()
			if !fileDescriptorsToSend.isEmpty {
				let fdToSendFds = fdToSendFds!
				for (fdInChild, fdToSend) in fileDescriptorsToSend {
					try send(fd: fdToSend.rawValue, destfd: fdInChild.rawValue, to: fdToSendFds.rawValue)
				}
				LibXctConfig.logger?.trace("Closing fd to send fds")
				try fdToSendFds.close()
			}
		} catch {
			/* We must call the termination handler manually then… */
			p.terminationHandler?(p)
		}
		
		return (p, streamGroup)
	}
	
	/**
	Exactly the same as `spawnedAndStreamedProcess`, but the process and the
	streamed file descriptors are waited on and you get the termination status
	and reason on return.
	
	- Returns: The exit status of the process and its termination reason. */
	public static func spawnAndStream(
		_ executable: String, args: [String] = [],
		stdin: FileDescriptor? = FileDescriptor.xctStdin,
		stdoutRedirect: RedirectMode = RedirectMode.none,
		stderrRedirect: RedirectMode = RedirectMode.none,
		fileDescriptorsToSend: [FileDescriptor /* Value in parent */: FileDescriptor /* Value in child */] = [:],
		additionalOutputFileDescriptors: Set<FileDescriptor> = [],
		signalsToForward: Set<Signal> = Signal.toForwardToSubprocesses,
		outputHandler: @escaping (_ line: String, _ sourceFd: FileDescriptor) -> Void
	) throws -> (Int32, Process.TerminationReason) {
		let (p, g) = try spawnedAndStreamedProcess(
			executable, args: args,
			stdin: stdin,
			stdoutRedirect: stdoutRedirect,
			stderrRedirect: stderrRedirect,
			fileDescriptorsToSend: fileDescriptorsToSend,
			additionalOutputFileDescriptors: additionalOutputFileDescriptors,
			signalsToForward: signalsToForward,
			outputHandler: outputHandler
		)
		
		p.waitUntilExit()
		g.wait()
		return (p.terminationStatus, p.terminationReason)
	}
	
	private static func setRequireNonBlockingIO(on fd: FileDescriptor, logChange: Bool) throws {
		let curFlags = fcntl(fd.rawValue, F_GETFL)
		guard curFlags != -1 else {
			throw LibXctError.systemError(Errno(rawValue: errno))
		}
		
		let newFlags = curFlags | O_NONBLOCK
		guard newFlags != curFlags else {
			/* Nothing to do */
			return
		}
		
		if logChange {
			/* We only log for fd that were not ours */
			LibXctConfig.logger?.info("Setting O_NONBLOCK option on fd \(fd)")
		}
		guard fcntl(fd.rawValue, F_SETFL, newFlags) != -1 else {
			throw LibXctError.systemError(Errno(rawValue: errno))
		}
	}
	
	private static func handleProcessOutput(streamSource: DispatchSourceRead, streamQueue: DispatchQueue, outputHandler: @escaping (String) -> Void, streamReader: GenericStreamReader, estimatedBytesAvailable: UInt, timerRef: Ref<DispatchSourceTimer?>, fromTimer: Bool) {
		timerRef.value?.setEventHandler(handler: nil)
		timerRef.value?.cancel()
		
		/* This timer thingy is probably not needed at all. The general idea was
		 * to avoid blocking in an infinite read of the output stream in case the
		 * dispatch source read “did not work” and we were never called in the
		 * event handler.
		 *
		 * We thought about this case when closing the fd before reading the
		 * stream ended (for tests). Turns out the dispatch source will not be
		 * called, but the system read function will also block. Period. Whether
		 * the fd was set non-blocking or not.
		 * So the timer will indeed call this method, but we will still be
		 * blocked, basically rendering this workaround useless.
		 * We could probably time the read function and stop it (how?) if it took
		 * too long, but 1/ how much is too long? 2/ if the user closes the file
		 * descriptor while being used by someone else, he deserves to suffer (doc
		 * says “It is invalid to close a file descriptor or deallocate a mach
		 * port that is currently being tracked by a dispatch source object before
		 * the cancellation handler is invoked.”). */
		let timer = DispatchSource.makeTimerSource(queue: streamQueue)
		timerRef.value = timer
		timer.setEventHandler(handler: {
			Process.handleProcessOutput(
				streamSource: streamSource,
				streamQueue: streamQueue,
				outputHandler: outputHandler,
				streamReader: streamReader,
				estimatedBytesAvailable: 1,
				timerRef: timerRef, fromTimer: true
			)
		})
		timer.schedule(deadline: .now() + .seconds(3))
		timer.activate()
		
		let cancelAllSources = {
			timerRef.value?.cancel()
			timerRef.value = nil
			streamSource.cancel()
		}
		
		do {
			/* A bit more than estimates to get everything. */
			let toRead = Int(estimatedBytesAvailable * 2 + 1)
			LibXctConfig.logger?.trace("Reading around \(toRead) bytes from \(streamReader.sourceStream), triggered by timer: \(fromTimer)")
			/* We do not need to check the number of bytes actually read. If EOF
			 * was reached (nothing was read), the stream reader will remember it,
			 * and the readLine method will properly return nil without even trying
			 * to read from the stream. Which matters, because we forbid the reader
			 * from reading from the underlying stream (except in this read). */
			_ = try streamReader.readStreamInBuffer(size: toRead, allowMoreThanOneRead: false, bypassUnderlyingStreamReadSizeLimit: true)
			
			while let (lineData, eolData) = try streamReader.readLine() {
				guard let line = String(data: lineData, encoding: .utf8),
						let eol = String(data: eolData, encoding: .utf8)
				else {
					LibXctConfig.logger?.error("Got unreadable line or eol from fd \(streamReader.sourceStream): eol = \(eolData.reduce("", { $0 + String(format: "%02x", $1) })); line = \(lineData.reduce("", { $0 + String(format: "%02x", $1) }))")
					return
				}
				outputHandler(line + eol)
			}
			/* We have read all the stream, we can stop */
			LibXctConfig.logger?.debug("End of stream reached; cancelling read stream for \(streamReader.sourceStream)")
			cancelAllSources()
			
		} catch StreamReaderError.streamReadForbidden {
			LibXctConfig.logger?.trace("Error reading from \(streamReader.sourceStream): stream read forbidden")
			
		} catch Errno.resourceTemporarilyUnavailable {
			LibXctConfig.logger?.trace("Error reading from \(streamReader.sourceStream): resource temporarily unavailable")
			
		} catch {
			LibXctConfig.logger?.warning("Error reading from \(streamReader.sourceStream): \(error)")
			/* We stop everything at first error. Most likely the error is bad fd
			 * because process exited and we were too long to read from the stream. */
			cancelAllSources()
		}
	}
	
	/* Based on https://stackoverflow.com/a/28005250 (last variant) */
	private static func send(fd: CInt, destfd: CInt, to socket: CInt) throws {
		var fd = fd /* A var because we use a pointer to it at some point, but never actually modified */
		let sizeOfFd = MemoryLayout.size(ofValue: fd) /* We’ll need this later */
		let sizeOfDestfd = MemoryLayout.size(ofValue: destfd) /* We’ll need this later */
		
		var msg = msghdr()
		
		/* We’ll place the destination fd (a simple CInt) in an iovec. */
		let iovBase = UnsafeMutablePointer<CInt>.allocate(capacity: 1)
		defer {iovBase.deallocate()}
		iovBase.initialize(to: destfd)
		
		let ioPtr = UnsafeMutablePointer<iovec>.allocate(capacity: 1)
		defer {ioPtr.deallocate()}
		ioPtr.initialize(to: iovec(iov_base: iovBase, iov_len: sizeOfDestfd))
		
		msg.msg_iov = ioPtr
		msg.msg_iovlen = 1
		
		/* Ancillary data. This is where we send the actual fd. */
		let buf = UnsafeMutablePointer<CInt>.allocate(capacity: 1)
		defer {buf.deallocate()}
		buf.initialize(to: -1)
		
		msg.msg_control = UnsafeMutableRawPointer(buf)
		msg.msg_controllen = socklen_t(XCT_CMSG_SPACE(sizeOfFd))
		
		guard let cmsg = XCT_CMSG_FIRSTHDR(&msg) else {
			throw LibXctError.internalError("CMSG_FIRSTHDR returned nil.")
		}
		
		cmsg.pointee.cmsg_type = SCM_RIGHTS
		cmsg.pointee.cmsg_level = SOL_SOCKET
		
		cmsg.pointee.cmsg_len = socklen_t(XCT_CMSG_LEN(sizeOfFd))
		memmove(XCT_CMSG_DATA(cmsg), &fd, sizeOfFd)
		
		guard sendmsg(socket, &msg, /*flags: */0) != -1 else {
			throw LibXctError.systemError(Errno(rawValue: errno))
		}
		LibXctConfig.logger?.debug("sent fd \(fd) through socket to child process")
	}
	
}


/**
A subclass of Process whose termination handler is overridden, in order for
libxct to set its own termination handler and still let clients use it. */
private class LibXctProcess : Process {
	
	var privateTerminationHandler: ((Process) -> Void)? {
		didSet {updateTerminationHandler()}
	}
	
	override init() {
		super.init()
		
		publicTerminationHandler = super.terminationHandler
		updateTerminationHandler()
	}
	
	override var terminationHandler: ((Process) -> Void)? {
		get {publicTerminationHandler}
		set {publicTerminationHandler = newValue; updateTerminationHandler()}
	}
	
	private var publicTerminationHandler: ((Process) -> Void)?
	
	/**
	Sets super’s terminationHandler to nil if both private and public termination
	handlers are nil, otherwise set it to call them. */
	private func updateTerminationHandler() {
		if privateTerminationHandler == nil && publicTerminationHandler == nil {
			super.terminationHandler = nil
		} else {
			super.terminationHandler = { process in
				(process as! LibXctProcess).privateTerminationHandler?(process)
				(process as! LibXctProcess).publicTerminationHandler?(process)
			}
		}
	}
	
}
