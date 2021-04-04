import Foundation

import SystemPackage

import CMacroExports



extension Process {
	
	/**
	How to redirect stdout and stderr? */
	public enum OutputRedirect {
		case none
		case toNull
		case capture
		case toFd(FileDescriptor)
	}
	
	/**
	Spawns a process, streams all of its outputs (stdout, stderr and all
	additional output file descriptors) in the handler (line by line, each line
	containing the newline char, a valid newline is only "\n", but line might not
	end with a newline if last line of the output), then waits for process to
	exit (in theory if output is over, process should be done, but process can
	close its output fd).
	
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
	child process. The key is the file descriptor to clone (from the parent
	process to the child), the value is the descriptor you’ll get in the child
	process.
	- Parameter additionalOutputFileDescriptor: Additional output file
	descriptors to stream from the process. Usually used with
	`fileDescriptorsToClone` (you open a socket, give the write fd in fds to
	clone, and the read fd to additional output fds).
	- Returns: The _started_ `Process` object that was created. */
	public static func spawnedAndStreamedProcess(
		_ executable: String, args: [String],
		stdin: FileDescriptor? = FileDescriptor.xctStdin,
		stdoutRedirect: OutputRedirect = OutputRedirect.none,
		stderrRedirect: OutputRedirect = OutputRedirect.none,
		fileDescriptorsToSend: [FileDescriptor /* Value in parent */: FileDescriptor /* Value in child */] = [:],
		additionalOutputFileDescriptors: [FileDescriptor] = [],
		signalsToForward: [Int32],
		outputHandler: (_ line: String, _ sourceFd: FileDescriptor) -> Void
	) throws -> Process {
		let p = Process()
		
		let streamQueue = DispatchQueue(label: "com.xcode-actions.spawn-and-stream")
		if additionalOutputFileDescriptors.isEmpty {
			p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
			p.arguments = [executable] + args
		} else {
			guard let execBaseURL = getenv(LibXctConstants.envVarNameExecPath).flatMap({ URL(fileURLWithPath: String(cString: $0)) }) else {
				LibXctConfig.logger?.error("Cannot launch process and send it fd if \(LibXctConstants.envVarNameExecPath) is not set.")
				throw LibXctError.envVarXctExecPathNotSet
			}
			p.executableURL = execBaseURL.appendingPathComponent("xct")
			p.arguments = [
				"internal-fd-get-launcher",
				"/usr/bin/env", executable
			] + args
		}
		
		for fd in /*[fileDescriptorForStdout, fileDescriptorForStderr].compactMap({ $0 }) + */additionalOutputFileDescriptors {
			let source = DispatchSource.makeReadSource(fileDescriptor: fd.rawValue, queue: streamQueue)
			source.setEventHandler{
				print("yo")
			}
			source.setCancelHandler{
			}
			source.resume()
		}
		
		try p.run()
		for (fdToSend, fdInChild) in fileDescriptorsToSend {
			
		}
		
		return p
	}
	
	/**
	Exactly the same as `spawnedAndStreamedProcess`, but the process is waited on
	and you get the termination status and reason on return.
	
	- Returns: The exit status of the process and its termination reason. */
	public static func spawnAndStreamProcess(
		_ executable: String, args: [String],
		stdin: FileDescriptor? = FileDescriptor.xctStdin,
		stdoutRedirect: OutputRedirect = OutputRedirect.none,
		stderrRedirect: OutputRedirect = OutputRedirect.none,
		fileDescriptorsToSend: [FileDescriptor /* Value in parent */: FileDescriptor /* Value in child */] = [:],
		additionalOutputFileDescriptors: [FileDescriptor] = [],
		signalsToForward: [Int32],
		outputHandler: (_ line: String, _ sourceFd: FileDescriptor) -> Void
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
	
	/* https://stackoverflow.com/a/28005250 (last variant) */
	private func send(fd: CInt, to socket: Int32) throws {
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

