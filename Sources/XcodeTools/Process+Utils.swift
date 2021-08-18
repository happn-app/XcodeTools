import Foundation

import StreamReader
import SystemPackage

import CMacroExports
import SignalHandling

#if canImport(eXtenderZ)
import CNSTaskHelptender
import eXtenderZ
#endif



#if canImport(eXtenderZ)
class XcodeToolsProcessExtender : NSObject, XCTTaskExtender {
	
	let additionalCompletionHandler: (Process) -> Void
	
	init(_ completionHandler: @escaping (Process) -> Void) {
		self.additionalCompletionHandler = completionHandler
	}
	
	func prepareObject(forExtender object: NSObject) -> Bool {return true}
	func prepareObjectForRemoval(ofExtender object: NSObject) {/*nop*/}
	
}
#endif

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
	 containing the newline char, a valid newline is only "\n", but line might
	 not end with a newline if last line of the output).
	 
	 The process will be launched in its own PGID. Which means, if your process
	 is launched in a Terminal, then you spawn a process using this method, then
	 the user types Ctrl-C, your process will be killed, but the process you
	 launched won’t be.
	 
	 However, you have an option to forward some signals to the processes you
	 spawn using this method.
	 
	 IMHO the signal forwarding method, though a bit more complex (in this case,
	 a lot of the complexity is hidden by this method), is better than using the
	 same PGID than the parent for the child. In a shell, if a long running
	 process is launched from a bash script, and said bash script is killed using
	 a signal (but from another process sending a signal, not from the tty), the
	 child won’t be killed! Using signal forwarding, it will.
	 
	 Some interesting links:
	 - [The TTY demystified](http://www.linusakesson.net/programming/tty/)
	 - [SIGTTIN / SIGTTOU Deep Dive](http://curiousthing.org/sigttin-sigttou-deep-dive-linux)
	 - [Swift Process class source code](https://github.com/apple/swift-corelibs-foundation/blob/swift-5.3.3-RELEASE/Sources/Foundation/Process.swift)
	 
	 - Important: For technical reasons (and design choice), if file descriptors
	 to send is not empty, the process will be launched _via_ `xct`.
	 
	 - Note: We use `Process` to spawn the process. This is why the process is
	 launched in its own PGID and why we have to use `xct` to launch it to be
	 able to pass other file descriptors than stdin/stdout/stderr to it.
	 
	 One day we might rewrite this function using `posix_spawn` directly…
	 
	 - Note: On Linux, the PGID stuff is not true up to Swift 5.3.3 (currently in
	 production!) It is true on the `main` branch though (2021-04-01).
	 
	 - Important: The handler will not be called on the calling thread (so you
	 can `waitUntilExit` on the `Process` and still receive the stream “live”).
	 
	 - Important: All of the `additionalOutputFileDescriptors` are closed when
	 the end of their respective stream are reached (i.e. the function takes
	 ownership of the file descriptors). Maybe later we’ll add an option not to
	 close at end of the stream.
	 
	 - Parameter fileDescriptorsToSend: The file descriptors (other than `stdin`,
	 `stdout` and `stderr`, which are handled and differently) to clone in the
	 child process. The **value** is the file descriptor to clone (from the
	 parent process to the child), the key is the descriptor you’ll get in the
	 child process.
	 - Parameter additionalOutputFileDescriptors: Additional output file
	 descriptors to stream from the process. Usually used with
	 `fileDescriptorsToSend` (you open a socket, give the write fd in fds to
	 clone, and the read fd to additional output fds). **Important**: The
	 function takes ownership of these file descriptors, i.e. it closes them when
	 the end of their respective streams is reached.
	 - Returns: The _started_ `Process` object that was created and a dispatch
	 group you can wait on to be sure the end of the streams was reached. */
	public static func spawnedAndStreamedProcess(
		_ executable: String, args: [String] = [],
		stdin: FileDescriptor? = FileDescriptor.standardInput,
		stdoutRedirect: RedirectMode = RedirectMode.none,
		stderrRedirect: RedirectMode = RedirectMode.none,
		fileDescriptorsToSend: [FileDescriptor /* Value in **child** */: FileDescriptor /* Value in **parent** */] = [:],
		additionalOutputFileDescriptors: Set<FileDescriptor> = [],
		signalsToForward: Set<Signal> = Signal.toForwardToSubprocesses,
		workingDirectory: URL? = nil, environment: [String: String]? = nil,
		outputHandler: @escaping (_ line: String, _ sourceFd: FileDescriptor) -> Void
	) throws -> (Process, DispatchGroup) {
#if canImport(eXtenderZ)
		let p = Process()
#else
		let p = XcodeToolsProcess()
#endif
		
		p.environment = environment
		p.currentDirectoryURL = workingDirectory
		
		var fdToCloseInCaseOfError = Set<FileDescriptor>()
		var mustCallTerminationHandlerInCaseOfError = false
		func cleanupAndThrow(_ error: Error) throws -> Never {
			if mustCallTerminationHandlerInCaseOfError {p.terminationHandler?(p)}
			fdToCloseInCaseOfError.forEach{ try? $0.close() }
			throw error
		}
		func cleanupIfThrows<R>(_ block: () throws -> R) rethrows -> R {
			do {return try block()}
			catch {
				try cleanupAndThrow(error)
			}
		}
		
		var fdRedirects = [FileDescriptor: FileDescriptor]()
		var outputFileDescriptors = additionalOutputFileDescriptors
		switch stdoutRedirect {
			case .none:         (/*nop*/)
			case .toNull:       p.standardOutput = nil
			case .toFd(let fd): p.standardOutput = FileHandle(fileDescriptor: fd.rawValue)
			case .capture:
				/* The Pipe init is non-fallible, but can fail. So we cast the Pipe
				 * returned by the init to a Pipe? */
				guard let pipe = Pipe() as Pipe? else {
					try cleanupAndThrow(XcodeToolsError.internalError("Cannot open Pipe for stdout"))
				}
				/* An alternative to the guard above:
				let pipe = Pipe()
				guard Unmanaged.passUnretained(pipe).toOpaque() != UnsafeMutableRawPointer(bitPattern: 0) else {
					try cleanupAndThrow(XcodeToolsError.internalError("Cannot open Pipe"))
				}*/
				
				let fdForReading = FileDescriptor(rawValue: pipe.fileHandleForReading.fileDescriptor)
				let fdForWriting = FileDescriptor(rawValue: pipe.fileHandleForWriting.fileDescriptor)
				
				let (inserted, _) = outputFileDescriptors.insert(fdForReading); assert(inserted)
				fdRedirects[fdForReading] = FileDescriptor.standardOutput
				
				fdToCloseInCaseOfError.insert(fdForReading)
				fdToCloseInCaseOfError.insert(fdForWriting)
				
				p.standardOutput = pipe
		}
		switch stderrRedirect {
			case .none:         (/*nop*/)
			case .toNull:       p.standardError = nil
			case .toFd(let fd): p.standardError = FileHandle(fileDescriptor: fd.rawValue)
			case .capture:
				guard let pipe = Pipe() as Pipe? else {
					try cleanupAndThrow(XcodeToolsError.internalError("Cannot open Pipe for stderr"))
				}
				
				let fdForReading = FileDescriptor(rawValue: pipe.fileHandleForReading.fileDescriptor)
				let fdForWriting = FileDescriptor(rawValue: pipe.fileHandleForWriting.fileDescriptor)
				
				let (inserted, _) = outputFileDescriptors.insert(fdForReading); assert(inserted)
				fdRedirects[fdForReading] = FileDescriptor.standardError
				
				fdToCloseInCaseOfError.insert(fdForReading)
				fdToCloseInCaseOfError.insert(fdForWriting)
				
				p.standardError = pipe
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
			guard let execBaseURL = getenv(XcodeToolsConstants.envVarNameExecPath).flatMap({ URL(fileURLWithPath: String(cString: $0)) }) else {
				XcodeToolsConfig.logger?.error("Cannot launch process and send its fd if \(XcodeToolsConstants.envVarNameExecPath) is not set.")
				try cleanupAndThrow(XcodeToolsError.envVarXctExecPathNotSet)
			}
			/* The socket to send the fd. The tuple thingy _should_ be _in effect_
			 * equivalent to the C version `int sv[2] = {-1, -1};`.
			 * https://forums.swift.org/t/guarantee-in-memory-tuple-layout-or-dont/40122
			 * Stride and alignment should be the equal for CInt.
			 * Funnily, it seems to only work in debug compilation, not in release…
			 * var sv: (CInt, CInt) = (-1, -1) */
			let sv = UnsafeMutablePointer<CInt>.allocate(capacity: 2)
			sv.initialize(repeating: -1, count: 2)
			defer {sv.deallocate()}
			guard socketpair(/*domain: */AF_UNIX, /*type: */SOCK_DGRAM, /*protocol: */0, /*socket_vector: */sv) == 0 else {
				/* TODO: Throw a more informative error? */
				try cleanupAndThrow(XcodeToolsError.systemError(Errno(rawValue: errno)))
			}
			let fdRaw0 = sv.advanced(by: 0).pointee
			let fdRaw1 = sv.advanced(by: 1).pointee
			assert(fdRaw0 != -1 && fdRaw1 != -1)
			
			fdToCloseInCaseOfError.insert(FileDescriptor(rawValue: fdRaw0))
			fdToCloseInCaseOfError.insert(FileDescriptor(rawValue: fdRaw1))
			
			p.executableURL = execBaseURL.appendingPathComponent("xct")
			p.arguments = ["internal-fd-get-launcher", executable] + args
			p.standardInput = FileHandle(fileDescriptor: fdRaw1)
			fdToSendFds = FileDescriptor(rawValue: fdRaw0)
			
			if fileDescriptorsToSend[FileDescriptor.standardInput] == nil {
				/* We must add stdin in the list of file descriptors to send. */
				fileDescriptorsToSend[FileDescriptor.standardInput] = FileDescriptor.standardInput
			}
		}
		
		let delayedSigations = try cleanupIfThrows{ try SigactionDelayer_Unsig.registerDelayedSigactions(signalsToForward, handler: { (signal, handler) in
			XcodeToolsConfig.logger?.debug("Handler action in Process+Utils", metadata: ["signal": "\(signal)"])
			defer {handler(true)}
			
			guard p.isRunning else {return}
			kill(p.processIdentifier, signal.rawValue)
		}) }
		
		let streamGroup = DispatchGroup()
		var readSources = [DispatchSourceRead]()
		let streamQueue = DispatchQueue(label: "com.xcode-actions.spawn-and-stream")
		for fd in outputFileDescriptors {
			let streamReader = FileDescriptorReader(stream: fd, bufferSize: 1024, bufferSizeIncrement: 512)
			streamReader.underlyingStreamReadSizeLimit = 0
			
			let streamSource = DispatchSource.makeReadSource(fileDescriptor: fd.rawValue, queue: streamQueue)
			readSources.append(streamSource)
			
			streamSource.setRegistrationHandler(handler: streamGroup.enter)
			streamSource.setCancelHandler{
				_ = try? fd.close()
				streamGroup.leave()
			}
			
			streamSource.setEventHandler{
				/* `source.data`: see doc of dispatch_source_get_data in objc */
				/* `source.mask`: see doc of dispatch_source_get_mask in objc (is always 0 for read source) */
				Process.handleProcessOutput(
					streamSource: streamSource,
					streamQueue: streamQueue,
					outputHandler: { str in outputHandler(str, fdRedirects[fd] ?? fd) },
					streamReader: streamReader,
					estimatedBytesAvailable: streamSource.data
				)
			}
		}
		
		readSources.forEach{ $0.activate() }
		
		let terminationHandler: (Process) -> Void = { _ in
			XcodeToolsConfig.logger?.debug("Called in termination handler of process")
			let errors = SigactionDelayer_Unsig.unregisterDelayedSigactions(Set(delayedSigations.values))
			for (signal, error) in errors {
				XcodeToolsConfig.logger?.error("Cannot unregister delayed sigaction: \(error)", metadata: ["signal": "\(signal)"])
			}
		}
#if canImport(eXtenderZ)
		p.hpn_add(XcodeToolsProcessExtender(terminationHandler))
#else
		p.privateTerminationHandler = terminationHandler
#endif
		
		XcodeToolsConfig.logger?.info("Launching process \(executable)\(fileDescriptorsToSend.isEmpty ? "" : " through xct")")
		mustCallTerminationHandlerInCaseOfError = true
		try cleanupIfThrows{
			try p.run()
			if !fileDescriptorsToSend.isEmpty {
				let fdToSendFds = fdToSendFds!
				for (fdInChild, fdToSend) in fileDescriptorsToSend {
					try send(fd: fdToSend.rawValue, destfd: fdInChild.rawValue, to: fdToSendFds.rawValue)
				}
				XcodeToolsConfig.logger?.trace("Closing fd to send fds")
				try fdToSendFds.close()
			}
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
		stdin: FileDescriptor? = FileDescriptor.standardInput,
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
			throw XcodeToolsError.systemError(Errno(rawValue: errno))
		}
		
		let newFlags = curFlags | O_NONBLOCK
		guard newFlags != curFlags else {
			/* Nothing to do */
			return
		}
		
		if logChange {
			/* We only log for fd that were not ours */
			XcodeToolsConfig.logger?.info("Setting O_NONBLOCK option on fd \(fd)")
		}
		guard fcntl(fd.rawValue, F_SETFL, newFlags) != -1 else {
			throw XcodeToolsError.systemError(Errno(rawValue: errno))
		}
	}
	
	private static func handleProcessOutput(streamSource: DispatchSourceRead, streamQueue: DispatchQueue, outputHandler: @escaping (String) -> Void, streamReader: GenericStreamReader, estimatedBytesAvailable: UInt) {
		do {
			/* A bit more than estimates to get everything. */
			let toRead = Int(estimatedBytesAvailable * 2 + 1)
			XcodeToolsConfig.logger?.trace("Reading around \(toRead) bytes from \(streamReader.sourceStream)")
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
					XcodeToolsConfig.logger?.error("Got unreadable line or eol from fd \(streamReader.sourceStream): eol = \(eolData.reduce("", { $0 + String(format: "%02x", $1) })); line = \(lineData.reduce("", { $0 + String(format: "%02x", $1) }))")
					return
				}
				outputHandler(line + eol)
			}
			/* We have read all the stream, we can stop */
			XcodeToolsConfig.logger?.debug("End of stream reached; cancelling read stream for \(streamReader.sourceStream)")
			streamSource.cancel()
			
		} catch StreamReaderError.streamReadForbidden {
			XcodeToolsConfig.logger?.trace("Error reading from \(streamReader.sourceStream): stream read forbidden")
			
		} catch Errno.resourceTemporarilyUnavailable {
			XcodeToolsConfig.logger?.trace("Error reading from \(streamReader.sourceStream): resource temporarily unavailable")
			
		} catch {
			XcodeToolsConfig.logger?.warning("Error reading from \(streamReader.sourceStream): \(error)")
			/* We stop everything at first error. Most likely the error is bad fd
			 * because process exited and we were too long to read from the stream. */
			streamSource.cancel()
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
			throw XcodeToolsError.internalError("CMSG_FIRSTHDR returned nil.")
		}
		
		cmsg.pointee.cmsg_type = SCM_RIGHTS
		cmsg.pointee.cmsg_level = SOL_SOCKET
		
		cmsg.pointee.cmsg_len = socklen_t(XCT_CMSG_LEN(sizeOfFd))
		memmove(XCT_CMSG_DATA(cmsg), &fd, sizeOfFd)
		
		guard sendmsg(socket, &msg, /*flags: */0) != -1 else {
			throw XcodeToolsError.systemError(Errno(rawValue: errno))
		}
		XcodeToolsConfig.logger?.debug("sent fd \(fd) through socket to child process")
	}
	
}


#if !canImport(eXtenderZ)
/**
 A subclass of Process whose termination handler is overridden, in order for
 XcodeTools to set its own termination handler and still let clients use it. */
private class XcodeToolsProcess : Process {
	
	var privateTerminationHandler: ((Process) -> Void)? {
		didSet {updateTerminationHandler()}
	}
	
	override init() {
		super.init()
		
		publicTerminationHandler = super.terminationHandler
		updateTerminationHandler()
	}
	
	override var terminationHandler: ((Process) -> Void)? {
		get {super.terminationHandler}
		set {publicTerminationHandler = newValue; updateTerminationHandler()}
	}
	
	private var publicTerminationHandler: ((Process) -> Void)?
	
	/**
	 Sets super’s terminationHandler to nil if both private and public
	 termination handlers are nil, otherwise set it to call them. */
	private func updateTerminationHandler() {
		if privateTerminationHandler == nil && publicTerminationHandler == nil {
			super.terminationHandler = nil
		} else {
			super.terminationHandler = { process in
				(process as! XcodeToolsProcess).privateTerminationHandler?(process)
				(process as! XcodeToolsProcess).publicTerminationHandler?(process)
			}
		}
	}
	
}
#endif
