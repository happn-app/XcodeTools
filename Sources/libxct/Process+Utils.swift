import Foundation

import StreamReader
import SystemPackage

import CMacroExports



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
	
	- Important: The `additionalOutputFileDescriptors` might be modified by this
	method to require non-blocking I/O.
	
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
	
	- Note: In addition to the process, we might want to return a `DispatchGroup`
	that would end when all of the streams are ended, so we can wait on that in
	addition to (or instead of) waiting on the end of the process.
	
	- Parameter fileDescriptorsToSend: The file descriptors (other than `stdin`,
	`stdout` and `stderr`, which are handled and differently) to clone in the
	child process. The key is the file descriptor to clone (from the parent
	process to the child), the value is the descriptor you’ll get in the child
	process.
	- Parameter additionalOutputFileDescriptor: Additional output file
	descriptors to stream from the process. Usually used with
	`fileDescriptorsToSend` (you open a socket, give the write fd in fds to
	clone, and the read fd to additional output fds). If they do not already, the
	file descriptors will probably be modified by this method to require non-
	blocking I/Os.
	- Returns: The _started_ `Process` object that was created. */
	public static func spawnedAndStreamedProcess(
		_ executable: String, args: [String] = [],
		stdin: FileDescriptor? = FileDescriptor.xctStdin,
		stdoutRedirect: RedirectMode = RedirectMode.none,
		stderrRedirect: RedirectMode = RedirectMode.none,
		fileDescriptorsToSend: [FileDescriptor /* Value in parent */: FileDescriptor /* Value in child */] = [:],
		additionalOutputFileDescriptors: Set<FileDescriptor> = [],
		signalsToForward: [Int32],
		outputHandler: @escaping (_ line: String, _ sourceFd: FileDescriptor) -> Void
	) throws -> Process {
		let p = Process()
		p.standardInput = stdin.flatMap{ FileHandle(fileDescriptor: $0.rawValue) }
		
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
		
		if fileDescriptorsToSend.isEmpty {
			p.executableURL = URL(fileURLWithPath: executable)
			p.arguments = args
		} else {
			guard let execBaseURL = getenv(LibXctConstants.envVarNameExecPath).flatMap({ URL(fileURLWithPath: String(cString: $0)) }) else {
				LibXctConfig.logger?.error("Cannot launch process and send its fd if \(LibXctConstants.envVarNameExecPath) is not set.")
				throw LibXctError.envVarXctExecPathNotSet
			}
			p.executableURL = execBaseURL.appendingPathComponent("xct")
			p.arguments = ["internal-fd-get-launcher", executable] + args
		}
		
		let streamQueue = DispatchQueue(label: "com.xcode-actions.spawn-and-stream")
		for fd in outputFileDescriptors {
			let notifiedFd = fdRedirects[fd] ?? fd
			try setRequireNonBlockingIO(on: fd, logChange: fd == notifiedFd)
			let streamReader = FileDescriptorReader(stream: fd, bufferSize: 1024, bufferSizeIncrement: 512)
			
			let source = DispatchSource.makeReadSource(fileDescriptor: fd.rawValue, queue: streamQueue)
			source.setEventHandler{
				/* This guard could probably be an assert */
				guard !source.isCancelled else {return}
				do {
					while let (lineData, eolData) = try streamReader.readLine() {
						guard let line = String(data: lineData, encoding: .utf8),
								let eol = String(data: eolData, encoding: .utf8)
						else {
							LibXctConfig.logger?.error("Got unreadable line or eol from fd \(streamReader.sourceStream): eol = \(eolData.reduce("", { $0 + String(format: "%02x", $1) })); line = \(lineData.reduce("", { $0 + String(format: "%02x", $1) }))")
							return
						}
						outputHandler(line + eol, notifiedFd)
					}
					/* We have read all the stream, we can stop */
					source.cancel()
				} catch let s as Errno where s == Errno.resourceTemporarilyUnavailable {
					/* This is a “normal” error, so we only log w/ trace level. */
					LibXctConfig.logger?.trace("Error reading fd \(streamReader.sourceStream): \(s)")
				} catch {
					LibXctConfig.logger?.warning("Error reading fd \(streamReader.sourceStream): \(error)")
				}
			}
			/* No cancel handler. Pipes file descriptors are closed when the Pipe
			 * object is released, that is when the Process object is deallocated.
			 * (TODO: Verify the sentence above is actually true!) */
			
			source.activate()
		}
		
		LibXctConfig.logger?.debug("Launching process \(executable)")
		try p.run()
		for (fdToSend, fdInChild) in fileDescriptorsToSend {
			
		}
		
		for signal in signalsToForward {
		}
		
		return p
	}
	
	/**
	Exactly the same as `spawnedAndStreamedProcess`, but the process is waited on
	and you get the termination status and reason on return.
	
	- Returns: The exit status of the process and its termination reason. */
	public static func spawnAndStream(
		_ executable: String, args: [String] = [],
		stdin: FileDescriptor? = FileDescriptor.xctStdin,
		stdoutRedirect: RedirectMode = RedirectMode.none,
		stderrRedirect: RedirectMode = RedirectMode.none,
		fileDescriptorsToSend: [FileDescriptor /* Value in parent */: FileDescriptor /* Value in child */] = [:],
		additionalOutputFileDescriptors: Set<FileDescriptor> = [],
		signalsToForward: [Int32],
		outputHandler: @escaping (_ line: String, _ sourceFd: FileDescriptor) -> Void
	) throws -> (Int32, Process.TerminationReason) {
		let p = try spawnedAndStreamedProcess(
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
	
	/* https://stackoverflow.com/a/28005250 (last variant) */
	private static func send(fd: CInt, to socket: Int32) throws {
		var fd = fd /* Because we use a pointer to it at some point, but never actually modified */
		
		var msg = msghdr()
		let bufSize = XCT_CMSG_SPACE(MemoryLayout.size(ofValue: fd))
		
		let buf = UnsafeMutablePointer<Int8>.allocate(capacity: bufSize)
		defer {buf.deallocate()}
		buf.assign(repeating: 0, count: bufSize)
		
		/* The struct iovec is needed, even if it points to minimal data. */
		let empty = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: MemoryLayout<Int8>.alignment)
		defer {empty.deallocate()}
		empty.initializeMemory(as: Int8.self, from: "", count: 1)
		
		let ioPtr = UnsafeMutablePointer<iovec>.allocate(capacity: 1)
		defer {ioPtr.deallocate()}
		ioPtr.initialize(to: iovec(iov_base: empty, iov_len: 1))
		
		msg.msg_iov = ioPtr
		msg.msg_iovlen = 1
		msg.msg_control = UnsafeMutableRawPointer(buf)
		msg.msg_controllen = socklen_t(bufSize)
		
		guard let cmsg = XCT_CMSG_FIRSTHDR(&msg) else {
			throw LibXctError.internalError("CMSG_FIRSTHDR returned nil.")
		}
		cmsg.pointee.cmsg_level = SOL_SOCKET
		cmsg.pointee.cmsg_type = SCM_RIGHTS
		cmsg.pointee.cmsg_len = socklen_t(XCT_CMSG_LEN(MemoryLayout.size(ofValue: fd)))
		
		memmove(XCT_CMSG_DATA(cmsg), &fd, MemoryLayout.size(ofValue: fd))
		LibXctConfig.logger?.debug("sent fd \(fd) through socket to child process")
		
		msg.msg_controllen = socklen_t(XCT_CMSG_SPACE(MemoryLayout.size(ofValue: fd)))
		
		guard sendmsg(socket, &msg, 0) >= 0 else {
			throw LibXctError.systemError(Errno(rawValue: errno))
		}
	}
	
}

