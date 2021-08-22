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
		/**
		 The stream should be redirected to this fd. If `giveOwnership` is true,
		 the fd will be closed when the process is run. Otherwise it is your
		 responsability to close it when needed. */
		case toFd(FileDescriptor, giveOwnership: Bool)
	}
	
	public enum LineSeparators {
		case newLine(unix: Bool, legacyMacOS: Bool, windows: Bool)
		case customCharacters(Set<UInt8>)
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
	 Additionally on Linux the fds will be set non-blocking (clients should not
	 care as they have given up ownership of the fd, but it’s still good to know
	 IMHO).
	 
	 - Important: AFAICT the absolute ref for `PATH` resolution is
	 [from exec function in FreeBSD source](https://opensource.apple.com/source/Libc/Libc-1439.100.3/gen/FreeBSD/exec.c.auto.html)
	 (end of file). Sadly `Process` does not report the actual errors and seem to
	 always report “File not found” errors when the executable cannot be run. So
	 we do not fully emulate exec’s behaviour.
	 
	 - Parameter usePATH: Try and search the executable in the `PATH` environment
	 variable when the executable path is a simple word (shell-like search). If
	 `false` (default) the standard `Process` behaviour will apply: resolve the
	 executable path just like any other path and execute that.
	 If not using `PATH` and there are fds to send, the `XCT_EXEC_PATH` env var
	 becomes mandatory. We have to know the location of the `xct` executable. If
	 using PATH with fds to send, the xct executable is searched normally, except
	 the `XCT_EXEC_PATH` path is tried first, if defined.
	 The environment is never modified (neither for the executed process nor the
	 current one), regardless of this variable or whether there are additional
	 fds to send.
	 The `PATH` is modified for the `xct` launcher when sending fds (and only for
	 it) so that all paths are absolute though. The subprocess will still see the
	 original `PATH`.
	 _Note_: Setting `usePATH` to `false` or `customPATH` to an empty array is
	 technically equivalent. (But setting `usePATH` to `false` is marginally
	 faster).
	 - Parameter customPATH: Override the PATH environment variable and use this.
	 Empty strings are the same as “`.`”. This parameter allows having a “PATH”
	 containing colons, which the standard `PATH` variable does not allow.
	 _However_ this does not work when there are fds to send, in which case the
	 paths containing colons are **removed** (for security reasons). Maybe one
	 day we’ll enable it in this case too, but for now it’s not enabled.
	 Another difference when there are fds to send regarding the PATH is all the
	 paths are made absolute. This avoids any problem when the `workingDirectory`
	 parameter is set to a non-null value.
	 Finally the parameter is a double-optional. It can be set to `.none`, which
	 means the default `PATH` env variable will be used, to `.some(.none)`, in
	 which case the default `PATH` is used (`_PATH_DEFPATH`, see `exec(3)`) or a
	 non-nil value, in which case this value is used.
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
		_ executable: FilePath, args: [String] = [], usePATH: Bool = false, customPATH: [FilePath]?? = nil,
		workingDirectory: URL? = nil, environment: [String: String]? = nil,
		stdin: FileDescriptor? = FileDescriptor.standardInput,
		stdoutRedirect: RedirectMode = RedirectMode.none,
		stderrRedirect: RedirectMode = RedirectMode.none,
		fileDescriptorsToSend: [FileDescriptor /* Value in **child** */: FileDescriptor /* Value in **parent** */] = [:],
		additionalOutputFileDescriptors: Set<FileDescriptor> = [],
		signalsToForward: Set<Signal> = Signal.toForwardToSubprocesses,
		lineSeparators: LineSeparators = .newLine(unix: true, legacyMacOS: false, windows: false),
		outputHandler: @escaping (_ line: Data, _ separator: Data, _ sourceFd: FileDescriptor) -> Void,
		terminationHandler: ((Process) -> Void)? = nil,
		ioDispatchGroup: DispatchGroup? = nil
	) throws -> Process {
#if canImport(eXtenderZ)
		let p = Process()
#else
		let p = XcodeToolsProcess()
#endif
		
		p.terminationHandler = terminationHandler
		if let environment      = environment      {p.environment         = environment}
		if let workingDirectory = workingDirectory {p.currentDirectoryURL = workingDirectory}
		
		var fdsToCloseInCaseOfError = Set<FileDescriptor>()
		var fdToSwitchToBlockingInCaseOfError = Set<FileDescriptor>()
		var countOfLeaveIODispatchGroupInCaseOfError = 0
		var signalCleaningOnError: (() -> Void)?
		func cleanupAndThrow(_ error: Error) throws -> Never {
			signalCleaningOnError?()
			if let g = ioDispatchGroup {for _ in 0..<countOfLeaveIODispatchGroupInCaseOfError {g.leave()}}
			
			/* Only the fds that are not ours, and thus not in additional output
			 * fds are allowed to be closed in case of error. */
			assert(additionalOutputFileDescriptors.intersection(fdsToCloseInCaseOfError).isEmpty)
			/* We only try and revert fds to blocking for fds we don’t own. Only
			 * those in additional output fds. */
			assert(additionalOutputFileDescriptors.isSuperset(of: fdToSwitchToBlockingInCaseOfError))
			/* The assert below is a consequence of the two above. */
			assert(fdsToCloseInCaseOfError.intersection(fdToSwitchToBlockingInCaseOfError).isEmpty)
			
			fdToSwitchToBlockingInCaseOfError.forEach{ fd in
				do    {try removeRequireNonBlockingIO(on: fd)}
				catch {Conf.logger?.error("Cannot revert fd \(fd.rawValue) to blocking.")}
			}
			fdsToCloseInCaseOfError.forEach{ try? $0.close() }
			
			throw error
		}
		func cleanupIfThrows<R>(_ block: () throws -> R) rethrows -> R {
			do {return try block()}
			catch {
				try cleanupAndThrow(error)
			}
		}
		
		var fdsToCloseAfterRun = Set<FileDescriptor>()
		var fdRedirects = [FileDescriptor: FileDescriptor]()
		var outputFileDescriptors = additionalOutputFileDescriptors
		switch stdoutRedirect {
			case .none: (/*nop*/)
			case .toNull: p.standardOutput = nil
			case .toFd(let fd, let shouldClose):
				p.standardOutput = FileHandle(fileDescriptor: fd.rawValue, closeOnDealloc: false)
				if shouldClose {fdsToCloseAfterRun.insert(fd)}
				
			case .capture:
				/* We use an unowned pipe because we want absolute control on when
				 * either side of the pipe is closed. */
				let (fdForReading, fdForWriting) = try Self.unownedPipe()
				
				let (inserted, _) = outputFileDescriptors.insert(fdForReading); assert(inserted)
				fdRedirects[fdForReading] = FileDescriptor.standardOutput
				
				fdsToCloseAfterRun.insert(fdForWriting)
				fdsToCloseInCaseOfError.insert(fdForReading)
				fdsToCloseInCaseOfError.insert(fdForWriting)
				
				Conf.logger?.trace("stdout pipe is r:\(fdForReading.rawValue) w:\(fdForWriting.rawValue)")
				p.standardOutput = FileHandle(fileDescriptor: fdForWriting.rawValue, closeOnDealloc: false)
		}
		switch stderrRedirect {
			case .none: (/*nop*/)
			case .toNull: p.standardError = nil
			case .toFd(let fd, let shouldClose):
				p.standardError = FileHandle(fileDescriptor: fd.rawValue, closeOnDealloc: false)
				if shouldClose {fdsToCloseAfterRun.insert(fd)}
				
			case .capture:
				let (fdForReading, fdForWriting) = try Self.unownedPipe()
				
				let (inserted, _) = outputFileDescriptors.insert(fdForReading); assert(inserted)
				fdRedirects[fdForReading] = FileDescriptor.standardError
				
				fdsToCloseAfterRun.insert(fdForWriting)
				fdsToCloseInCaseOfError.insert(fdForReading)
				fdsToCloseInCaseOfError.insert(fdForWriting)
				
				Conf.logger?.trace("stderr pipe is r:\(fdForReading.rawValue) w:\(fdForWriting.rawValue)")
				p.standardError = FileHandle(fileDescriptor: fdForWriting.rawValue, closeOnDealloc: false)
		}
		
#if os(Linux)
		/* I did not find any other way than using non-blocking IO on Linux.
		 * https://stackoverflow.com/questions/39173429/one-shot-level-triggered-epoll-does-epolloneshot-imply-epollet/46142976#comment121697690_46142976 */
		for fd in outputFileDescriptors {
			try cleanupIfThrows{
				let isFromClient = additionalOutputFileDescriptors.contains(fd)
				try setRequireNonBlockingIO(on: fd, logChange: isFromClient)
				if isFromClient {
					/* The fd is not ours. We must try and revert it to its original
					 * state if the function throws an error. */
					assert(!fdsToCloseInCaseOfError.contains(fd))
					fdToSwitchToBlockingInCaseOfError.insert(fd)
				}
			}
		}
#endif
		
		let fdToSendFds: FileDescriptor?
		/* We will modify it later to add stdin if needed */
		var fileDescriptorsToSend = fileDescriptorsToSend
		
		/* Let’s compute the PATH. */
		/** The resolved PATH */
		let PATH: [FilePath]
		/** `true` if the default `_PATH_DEFPATH` path is used. The variable is
		 used when using the `xct` launcher. */
		let isDefaultPATH: Bool
		/** Set if we use the `xct` launcher. */
		let forcedPreprendedPATH: FilePath?
		if usePATH {
			if case .some(.some(let p)) = customPATH {
				PATH = p
				isDefaultPATH = false
			} else {
				let PATHstr: String
				if case .some(.none) = customPATH {
					/* We use the default path: _PATH_DEFPATH */
					PATHstr = _PATH_DEFPATH
					isDefaultPATH = true
				} else {
					/* We use the PATH env var */
					let envPATHstr = getenv("PATH").flatMap{ String(cString: $0) }
					PATHstr = envPATHstr ?? _PATH_DEFPATH
					isDefaultPATH = (envPATHstr == nil)
				}
				PATH = PATHstr.split(separator: ":", omittingEmptySubsequences: false).map{ FilePath(String($0)) }
			}
		} else {
			PATH = []
			isDefaultPATH = false
		}
		
		let actualExecutablePath: FilePath
		if fileDescriptorsToSend.isEmpty {
			/* We add closeOnDealloc:false to be explicit, but it’s the default. */
			p.standardInput = stdin.flatMap{ FileHandle(fileDescriptor: $0.rawValue, closeOnDealloc: false) }
			p.arguments = args
			actualExecutablePath = executable
			forcedPreprendedPATH = nil
			fdToSendFds = nil
		} else {
			let execBasePath = getenv(XcodeToolsConstants.envVarNameExecPath).flatMap{ FilePath(String(cString: $0)) }
			if !usePATH {
				guard let execBasePath = execBasePath else {
					XcodeToolsConfig.logger?.error("Cannot launch process and send its fd if \(XcodeToolsConstants.envVarNameExecPath) is not set.")
					try cleanupAndThrow(XcodeToolsError.envVarXctExecPathNotSet)
				}
				actualExecutablePath = execBasePath.appending("xct")
				forcedPreprendedPATH = nil
			} else {
				actualExecutablePath = "xct"
				forcedPreprendedPATH = execBasePath
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
#if !os(Linux)
			let sockDgram = SOCK_DGRAM
#else
			let sockDgram = Int32(SOCK_DGRAM.rawValue)
#endif
			guard socketpair(/*domain: */AF_UNIX, /*type: */sockDgram, /*protocol: */0, /*socket_vector: */sv) == 0 else {
				/* TODO: Throw a more informative error? */
				try cleanupAndThrow(XcodeToolsError.systemError(Errno(rawValue: errno)))
			}
			let fd0 = FileDescriptor(rawValue: sv.advanced(by: 0).pointee)
			let fd1 = FileDescriptor(rawValue: sv.advanced(by: 1).pointee)
			assert(fd0.rawValue != -1 && fd1.rawValue != -1)
			
			fdsToCloseAfterRun.insert(fd1)
			fdsToCloseInCaseOfError.insert(fd0)
			fdsToCloseInCaseOfError.insert(fd1)
			
			let cwd = FilePath(FileManager.default.currentDirectoryPath)
			if !cwd.isAbsolute {XcodeToolsConfig.logger?.error("currentDirectoryPath is not abolute! Madness may ensue.", metadata: ["path": "\(cwd)"])}
			/* We make all paths absolute, and filter the ones containing colons. */
			let PATHstr = (!isDefaultPATH ? PATH.map{ cwd.pushing($0).string }.filter{ $0.firstIndex(of: ":") == nil }.joined(separator: ":") : nil)
			let PATHoption = PATHstr.flatMap{ ["--path", $0] } ?? []
			
			p.arguments = ["internal-fd-get-launcher", usePATH ? "--use-path" : "--no-use-path"] + PATHoption + [executable.string] + args
			p.standardInput = FileHandle(fileDescriptor: fd1.rawValue, closeOnDealloc: false)
			fdToSendFds = fd0
			
			if fileDescriptorsToSend[FileDescriptor.standardInput] == nil {
				/* We must add stdin in the list of file descriptors to send so that
				 * stdin is restored to its original value when the final process is
				 * exec’d from xct. */
				fileDescriptorsToSend[FileDescriptor.standardInput] = FileDescriptor.standardInput
			}
		}
		
		let delayedSigations = try cleanupIfThrows{ try SigactionDelayer_Unsig.registerDelayedSigactions(signalsToForward, handler: { (signal, handler) in
			XcodeToolsConfig.logger?.debug("Handler action in Process+Utils", metadata: ["signal": "\(signal)"])
			defer {handler(true)}
			
			guard p.isRunning else {return}
			kill(p.processIdentifier, signal.rawValue)
		}) }
		let signalCleanupHandler = {
			let errors = SigactionDelayer_Unsig.unregisterDelayedSigactions(Set(delayedSigations.values))
			for (signal, error) in errors {
				XcodeToolsConfig.logger?.error("Cannot unregister delayed sigaction: \(error)", metadata: ["signal": "\(signal)"])
			}
		}
		signalCleaningOnError = signalCleanupHandler
		
		let additionalTerminationHandler: (Process) -> Void = { _ in
			XcodeToolsConfig.logger?.debug("Called in termination handler of process")
			signalCleanupHandler()
		}
#if canImport(eXtenderZ)
		p.hpn_add(XcodeToolsProcessExtender(additionalTerminationHandler))
#else
		p.privateTerminationHandler = additionalTerminationHandler
#endif
		
		/* We used to enter the dispatch group in the registration handlers of the
		 * dispatch sources, but we got races where the executable ended before
		 * the distatch sources were even registered. So now we enter the group
		 * before launching the executable. */
		if let ioDispatchGroup = ioDispatchGroup {
			countOfLeaveIODispatchGroupInCaseOfError = outputFileDescriptors.count
			for _ in 0..<countOfLeaveIODispatchGroupInCaseOfError {
				ioDispatchGroup.enter()
			}
		}
		
		XcodeToolsConfig.logger?.info("Launching process \(executable)\(fileDescriptorsToSend.isEmpty ? "" : " through xct")")
		try cleanupIfThrows{
			let actualPATH = [forcedPreprendedPATH].compactMap{ $0 } + PATH
			func tryPaths(from index: Int, executableComponent: FilePath.Component) throws {
				do {
					let url = URL(fileURLWithPath: actualPATH[index].appending([executableComponent]).string)
					XcodeToolsConfig.logger?.debug("Trying path \(url.path)")
					p.executableURL = url
					try p.run()
				} catch {
					let nserror = error as NSError
					switch (nserror.domain, nserror.code) {
						case (NSCocoaErrorDomain, NSFileNoSuchFileError) /* Apple platforms */,
							  (NSCocoaErrorDomain, CocoaError.Code.fileReadNoSuchFile.rawValue) /* Linux */:
							let nextIndex = actualPATH.index(after: index)
							if nextIndex < actualPATH.endIndex {
								try tryPaths(from: nextIndex, executableComponent: executableComponent)
							} else {
								throw error
							}
							
						default:
							throw error
					}
				}
			}
			if usePATH, !actualPATH.isEmpty, !actualExecutablePath.isAbsolute, actualExecutablePath.components.count == 1, let component = actualExecutablePath.components.last {
				try tryPaths(from: actualPATH.startIndex, executableComponent: component)
			} else {
				p.executableURL = URL(fileURLWithPath: actualExecutablePath.string)
				try p.run()
			}
			try fdsToCloseAfterRun.forEach{
				try $0.close()
				fdsToCloseInCaseOfError.remove($0)
			}
			signalCleaningOnError = nil
			if !fileDescriptorsToSend.isEmpty {
				let fdToSendFds = fdToSendFds!
				try withUnsafeBytes(of: Int32(fileDescriptorsToSend.count), { bytes in
					guard try fdToSendFds.write(bytes) == bytes.count else {
						throw Err.internalError("Unexpected count of sent bytes to fdToSendFds")
					}
				})
				for (fdInChild, fdToSend) in fileDescriptorsToSend {
					try send(fd: fdToSend.rawValue, destfd: fdInChild.rawValue, to: fdToSendFds.rawValue)
				}
				XcodeToolsConfig.logger?.trace("Closing fd to send fds")
				try fdToSendFds.close()
				fdsToCloseInCaseOfError.remove(fdToSendFds) /* Not really useful there cannot be any more errors from there. */
			}
		}
		
		for fd in outputFileDescriptors {
			let streamReader = FileDescriptorReader(stream: fd, bufferSize: 1024, bufferSizeIncrement: 512)
			streamReader.underlyingStreamReadSizeLimit = 0
			
			let streamSource = DispatchSource.makeReadSource(fileDescriptor: fd.rawValue, queue: Self.streamQueue)
			streamSource.setCancelHandler{
				_ = try? fd.close()
				ioDispatchGroup?.leave()
			}
			streamSource.setEventHandler{
				/* `source.data`: see doc of dispatch_source_get_data in objc */
				/* `source.mask`: see doc of dispatch_source_get_mask in objc (is always 0 for read source) */
				Process.handleProcessOutput(
					streamSource: streamSource,
					streamQueue: streamQueue,
					lineSeparators: lineSeparators,
					outputHandler: { line, sep in outputHandler(line, sep, fdRedirects[fd] ?? fd) },
					streamReader: streamReader,
					estimatedBytesAvailable: streamSource.data
				)
			}
			streamSource.activate()
		}
		
		return p
	}
	
	/**
	 Exactly the same as `spawnedAndStreamedProcess`, but the process and the
	 streamed file descriptors are waited on and you get the termination status
	 and reason on return.
	 
	 - Returns: The exit status of the process and its termination reason. */
	public static func spawnAndStream(
		_ executable: FilePath, args: [String] = [], usePATH: Bool = false, customPATH: [FilePath]?? = nil,
		workingDirectory: URL? = nil, environment: [String: String]? = nil,
		stdin: FileDescriptor? = FileDescriptor.standardInput,
		stdoutRedirect: RedirectMode = RedirectMode.none,
		stderrRedirect: RedirectMode = RedirectMode.none,
		fileDescriptorsToSend: [FileDescriptor /* Value in parent */: FileDescriptor /* Value in child */] = [:],
		additionalOutputFileDescriptors: Set<FileDescriptor> = [],
		signalsToForward: Set<Signal> = Signal.toForwardToSubprocesses,
		lineSeparators: LineSeparators = .newLine(unix: true, legacyMacOS: false, windows: false),
		outputHandler: @escaping (_ line: Data, _ separator: Data, _ sourceFd: FileDescriptor) -> Void
	) async throws -> (Int32, Process.TerminationReason) {
		try await withCheckedThrowingContinuation{ continuation in
			do {
				let g = DispatchGroup()
				_ = try spawnedAndStreamedProcess(
					executable, args: args, usePATH: usePATH, customPATH: customPATH,
					workingDirectory: workingDirectory, environment: environment,
					stdin: stdin, stdoutRedirect: stdoutRedirect, stderrRedirect: stderrRedirect,
					fileDescriptorsToSend: fileDescriptorsToSend,
					additionalOutputFileDescriptors: additionalOutputFileDescriptors,
					signalsToForward: signalsToForward,
					lineSeparators: lineSeparators,
					outputHandler: outputHandler,
					terminationHandler: { p in
						g.notify(queue: Self.streamQueue, execute: {
							Conf.logger?.trace("io group wait is over")
							continuation.resume(returning: (p.terminationStatus, p.terminationReason))
						})
					},
					ioDispatchGroup: g
				)
			} catch {
				continuation.resume(throwing: error)
			}
		}
	}
	
	public static func spawnAndGetOutput(
		_ executable: FilePath, args: [String] = [], usePATH: Bool = false, customPATH: [FilePath]?? = nil,
		workingDirectory: URL? = nil, environment: [String: String]? = nil,
		stdin: FileDescriptor? = FileDescriptor.standardInput,
		fileDescriptorsToSend: [FileDescriptor /* Value in parent */: FileDescriptor /* Value in child */] = [:],
		additionalOutputFileDescriptors: Set<FileDescriptor> = [],
		signalsToForward: Set<Signal> = Signal.toForwardToSubprocesses,
		lineSeparators: LineSeparators = .newLine(unix: true, legacyMacOS: false, windows: false)
	) async throws -> (exitCode: Int32, exitReason: Process.TerminationReason, outputs: [FileDescriptor: [(Data, Data)]]) {
		var outputs = [FileDescriptor: [(Data, Data)]]()
		let (exitCode, exitReason) = try await spawnAndStream(
			executable, args: args, usePATH: usePATH, customPATH: customPATH,
			workingDirectory: workingDirectory, environment: environment,
			stdin: stdin, stdoutRedirect: .capture, stderrRedirect: .capture,
			fileDescriptorsToSend: fileDescriptorsToSend,
			additionalOutputFileDescriptors: additionalOutputFileDescriptors,
			signalsToForward: signalsToForward,
			lineSeparators: lineSeparators,
			outputHandler: { line, separator, fd in outputs[fd, default: []].append((line, separator)) }
		)
		
		return (exitCode, exitReason, outputs)
	}
	
	public static func checkedSpawnAndGetOutput(
		_ executable: FilePath, args: [String] = [], usePATH: Bool = false, customPATH: [FilePath]?? = nil,
		workingDirectory: URL? = nil, environment: [String: String]? = nil,
		stdin: FileDescriptor? = FileDescriptor.standardInput,
		fileDescriptorsToSend: [FileDescriptor /* Value in parent */: FileDescriptor /* Value in child */] = [:],
		additionalOutputFileDescriptors: Set<FileDescriptor> = [],
		signalsToForward: Set<Signal> = Signal.toForwardToSubprocesses,
		lineSeparators: LineSeparators = .newLine(unix: true, legacyMacOS: false, windows: false),
		expectedTerminationStatus: Int32 = 0, expectedTerminationReason: Process.TerminationReason = .exit
	) async throws -> [FileDescriptor: [(Data, Data)]] {
		let (exitCode, exitReason, outputs) = try await spawnAndGetOutput(
			executable, args: args, usePATH: usePATH, customPATH: customPATH,
			workingDirectory: workingDirectory, environment: environment,
			stdin: stdin, fileDescriptorsToSend: fileDescriptorsToSend, additionalOutputFileDescriptors: additionalOutputFileDescriptors,
			signalsToForward: signalsToForward,
			lineSeparators: lineSeparators
		)
		guard exitCode == expectedTerminationStatus, exitReason == expectedTerminationReason else {
			throw Err.unexpectedSubprocessExit(terminationStatus: exitCode, terminationReason: exitReason)
		}
		return outputs
	}
	
	/**
	 Exactly the same as `spawnedAndStreamedProcess`, but the process and the
	 streamed file descriptors are waited on and you get the termination status
	 and reason on return.
	 
	 - Returns: The exit status of the process and its termination reason. */
	@available(macOS, deprecated: 12, message: "Use async version of this method")
	public static func spawnAndStream(
		_ executable: FilePath, args: [String] = [], usePATH: Bool = false, customPATH: [FilePath]?? = nil,
		workingDirectory: URL? = nil, environment: [String: String]? = nil,
		stdin: FileDescriptor? = FileDescriptor.standardInput,
		stdoutRedirect: RedirectMode = RedirectMode.none,
		stderrRedirect: RedirectMode = RedirectMode.none,
		fileDescriptorsToSend: [FileDescriptor /* Value in parent */: FileDescriptor /* Value in child */] = [:],
		additionalOutputFileDescriptors: Set<FileDescriptor> = [],
		signalsToForward: Set<Signal> = Signal.toForwardToSubprocesses,
		lineSeparators: LineSeparators = .newLine(unix: true, legacyMacOS: false, windows: false),
		outputHandler: @escaping (_ line: Data, _ separator: Data, _ sourceFd: FileDescriptor) -> Void
	) throws -> (Int32, Process.TerminationReason) {
		let g = DispatchGroup()
		let p = try spawnedAndStreamedProcess(
			executable, args: args, usePATH: usePATH, customPATH: customPATH,
			workingDirectory: workingDirectory,
			environment: environment,
			stdin: stdin,
			stdoutRedirect: stdoutRedirect,
			stderrRedirect: stderrRedirect,
			fileDescriptorsToSend: fileDescriptorsToSend,
			additionalOutputFileDescriptors: additionalOutputFileDescriptors,
			signalsToForward: signalsToForward,
			lineSeparators: lineSeparators,
			outputHandler: outputHandler,
			ioDispatchGroup: g
		)
		
		Conf.logger?.trace("Waiting for process to exit...")
		p.waitUntilExit()
		Conf.logger?.trace("Waiting for io to finish...")
		g.wait()
		Conf.logger?.trace("Wait is over.")
		return (p.terminationStatus, p.terminationReason)
	}
	
	@available(macOS, deprecated: 12, message: "Use async version of this method")
	public static func spawnAndGetOutput(
		_ executable: FilePath, args: [String] = [], usePATH: Bool = false, customPATH: [FilePath]?? = nil,
		workingDirectory: URL? = nil, environment: [String: String]? = nil,
		stdin: FileDescriptor? = FileDescriptor.standardInput,
		fileDescriptorsToSend: [FileDescriptor /* Value in parent */: FileDescriptor /* Value in child */] = [:],
		additionalOutputFileDescriptors: Set<FileDescriptor> = [],
		signalsToForward: Set<Signal> = Signal.toForwardToSubprocesses,
		lineSeparators: LineSeparators = .newLine(unix: true, legacyMacOS: false, windows: false)
	) throws -> (exitCode: Int32, exitReason: Process.TerminationReason, outputs: [FileDescriptor: [(Data, Data)]]) {
		var outputs = [FileDescriptor: [(Data, Data)]]()
		let (exitCode, exitReason) = try spawnAndStream(
			executable, args: args, usePATH: usePATH, customPATH: customPATH,
			workingDirectory: workingDirectory,
			environment: environment,
			stdin: stdin,
			stdoutRedirect: .capture,
			stderrRedirect: .capture,
			fileDescriptorsToSend: fileDescriptorsToSend,
			additionalOutputFileDescriptors: additionalOutputFileDescriptors,
			signalsToForward: signalsToForward,
			lineSeparators: lineSeparators,
			outputHandler: { line, separator, fd in outputs[fd, default: []].append((line, separator)) }
		)
		
		return (exitCode, exitReason, outputs)
	}
	
	/**
	 Returns a simple pipe. Different than using the `Pipe()` object from
	 Foundation because you get control on when the fds are closed.
	 
	 - Important: The FileDescriptor returned **must** be closed manually. */
	public static func unownedPipe() throws -> (fdRead: FileDescriptor, fdWrite: FileDescriptor) {
		/* Do **NOT** use a `Pipe` object! (Or dup the fds you get from it). Pipe
		 * closes both ends of the pipe on dealloc, but we need to close one at a
		 * specific time and leave the other open (it is closed in child process). */
		let pipepointer = UnsafeMutablePointer<CInt>.allocate(capacity: 2)
		defer {pipepointer.deallocate()}
		pipepointer.initialize(to: -1)
		
		guard pipe(pipepointer) == 0 else {
			throw Err.systemError(Errno(rawValue: errno))
		}
		
		let fdRead  = pipepointer.advanced(by: 0).pointee
		let fdWrite = pipepointer.advanced(by: 1).pointee
		assert(fdRead != -1 && fdWrite != -1)
		
		return (FileDescriptor(rawValue: fdRead), FileDescriptor(rawValue: fdWrite))
	}
	
	private static let streamQueue = DispatchQueue(label: "com.xcode-actions.process-spawn")
	
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
			XcodeToolsConfig.logger?.warning("Setting O_NONBLOCK option on fd \(fd)")
		}
		guard fcntl(fd.rawValue, F_SETFL, newFlags) != -1 else {
			throw XcodeToolsError.systemError(Errno(rawValue: errno))
		}
	}
	
	private static func removeRequireNonBlockingIO(on fd: FileDescriptor) throws {
		let curFlags = fcntl(fd.rawValue, F_GETFL)
		guard curFlags != -1 else {
			throw XcodeToolsError.systemError(Errno(rawValue: errno))
		}
		
		let newFlags = curFlags & ~O_NONBLOCK
		guard newFlags != curFlags else {
			/* Nothing to do */
			return
		}
		
		guard fcntl(fd.rawValue, F_SETFL, newFlags) != -1 else {
			throw XcodeToolsError.systemError(Errno(rawValue: errno))
		}
	}
	
	private static func handleProcessOutput(streamSource: DispatchSourceRead, streamQueue: DispatchQueue, lineSeparators: LineSeparators, outputHandler: @escaping (Data, Data) -> Void, streamReader: GenericStreamReader, estimatedBytesAvailable: UInt) {
		do {
			let toRead = Int(min(max(estimatedBytesAvailable, 1), UInt(Int.max)))
#if !os(Linux)
			/* We do not need to check the number of bytes actually read. If EOF
			 * was reached (nothing was read), the stream reader will remember it,
			 * and the readLine method will properly return nil without even trying
			 * to read from the stream. Which matters, because we forbid the reader
			 * from reading from the underlying stream (except in these read). */
			XcodeToolsConfig.logger?.trace("Reading around \(toRead) bytes from \(streamReader.sourceStream)")
			_ = try streamReader.readStreamInBuffer(size: toRead, allowMoreThanOneRead: false, bypassUnderlyingStreamReadSizeLimit: true)
#else
			XcodeToolsConfig.logger?.trace("In libdispatch callback for \(streamReader.sourceStream)")
			/* On Linux we have to use non-blocking IO for some reason. I’d say
			 * it’s a libdispatch bug, but I’m not sure.
			 * https://stackoverflow.com/questions/39173429/one-shot-level-triggered-epoll-does-epolloneshot-imply-epollet/46142976#comment121697690_46142976 */
			let read: () throws -> Int = {
				XcodeToolsConfig.logger?.trace("Reading around \(toRead) bytes from \(streamReader.sourceStream)")
				return try streamReader.readStreamInBuffer(size: toRead, allowMoreThanOneRead: false, bypassUnderlyingStreamReadSizeLimit: true)
			}
			let processError: (Error) -> Result<Int, Error> = { e in
				if case Errno.resourceTemporarilyUnavailable = e {
					XcodeToolsConfig.logger?.trace("Masking resource temporarily unavailable error")
					return .success(0)
				}
				return .failure(e)
			}
			while try Result(catching: read).flatMapError(processError).get() >= toRead {/*nop*/}
#endif
			
			let readLine: () throws -> (Data, Data)?
			switch lineSeparators {
				case .newLine(let unix, let legacyMacOS, let windows):
					readLine = {
						try streamReader.readLine(allowUnixNewLines: unix, allowLegacyMacOSNewLines: legacyMacOS, allowWindowsNewLines: windows)
					}
					
				case .customCharacters(let set):
					readLine = {
						let ret = try streamReader.readData(upTo: set.map{ Data([$0]) }, matchingMode: .shortestDataWins, failIfNotFound: false, includeDelimiter: false)
						_ = try streamReader.readData(size: ret.delimiter.count, allowReadingLess: false)
						guard !ret.data.isEmpty || !ret.delimiter.isEmpty else {
							return nil
						}
						return ret
					}
			}
			while let (lineData, eolData) = try readLine() {
				outputHandler(lineData, eolData)
			}
			/* We have read all the stream, we can stop */
			XcodeToolsConfig.logger?.debug("End of stream reached; cancelling read stream for \(streamReader.sourceStream)")
			streamSource.cancel()
			
		} catch StreamReaderError.streamReadForbidden {
			XcodeToolsConfig.logger?.trace("Error reading from \(streamReader.sourceStream): stream read forbidden (this is normal)")
			
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
		let buf = UnsafeMutableRawPointer.allocate(byteCount: XCT_CMSG_SPACE(sizeOfFd), alignment: MemoryLayout<cmsghdr>.alignment)
		defer {buf.deallocate()}
		
#if !os(Linux)
		msg.msg_control = UnsafeMutableRawPointer(buf)
		msg.msg_controllen = socklen_t(XCT_CMSG_SPACE(sizeOfFd))
#else
		msg.msg_control = UnsafeMutableRawPointer(buf)
		msg.msg_controllen = Int(XCT_CMSG_SPACE(sizeOfFd))
#endif
		
		guard let cmsg = XCT_CMSG_FIRSTHDR(&msg) else {
			throw XcodeToolsError.internalError("CMSG_FIRSTHDR returned nil.")
		}
		
#if !os(Linux)
		cmsg.pointee.cmsg_type = SCM_RIGHTS
		cmsg.pointee.cmsg_level = SOL_SOCKET
#else
		cmsg.pointee.cmsg_type = Int32(SCM_RIGHTS)
		cmsg.pointee.cmsg_level = SOL_SOCKET
#endif
		
#if !os(Linux)
		cmsg.pointee.cmsg_len = socklen_t(XCT_CMSG_LEN(sizeOfFd))
#else
		cmsg.pointee.cmsg_len = Int(XCT_CMSG_LEN(sizeOfFd))
#endif
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
	
	deinit {
		Conf.logger?.trace("Deinit of an XcodeToolsProcess")
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
