import Foundation

import ArgumentParser
import CLTLogger
import CMacroExports
import Logging
import SystemPackage



/* Big up to https://github.com/jjrscott/XcodeBuildResultStream */
struct XctBuild : ParsableCommand {
	
	static let execPathEnvVarName = "XCT_EXEC_PATH"
	
	static var configuration = CommandConfiguration(
		abstract: "Build an Xcode project",
		discussion: "Hopefully, the options supported by this tool are easier to understand than xcodebuild’s."
	)
	
	static var logger: Logger = {
		LoggingSystem.bootstrap{ _ in CLTLogger(messageTerminator: "\n") }
		return Logger(label: "main")
	}()
	
	@Option
	var xcodebuildPath: String = "/usr/bin/xcodebuild"
	
	func run() throws {
		guard let execBaseURL = getenv(XctBuild.execPathEnvVarName).flatMap({ URL(fileURLWithPath: String(cString: $0)) }) else {
			XctBuild.logger.error("Expected XCT_EXEC_PATH to be set! If you ran xct-build manually (instead of using \"xct build\"), please set it.")
			/* TODO: Use an actual error */
			throw ExitCode(rawValue: 1)
		}
		
		let pipe = Pipe()
		let fdXcodeReadOutput = pipe.fileHandleForReading.fileDescriptor
		let fdXcodeWriteOutput = pipe.fileHandleForWriting.fileDescriptor
		let resultBundlePath = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("xcresult").path
		/* TODO: When SystemPackage is updated, use FilePath (not interesting to
		 * use in version 0.0.1) */
		let resultStreamPath = "/dev/fd/$TRANSFERRED_FD"
		
		/* We want to launch xcodebuild, but w/ more than just stdin, stdout and
		 * stderr correctly dup’d (which Process does correctly); we also need to
		 * dup fdXcodeWriteOutput (presumably via posix_spawn_file_actions_adddup2
		 * or such), but Process does not let us do that!
		 * So instead we launch an internal launcher, which will wait until it
		 * receives the fd via a recvmsg(), which will make it valid inside the
		 * child process (IIUC; see https://stackoverflow.com/a/28005250 for more
		 * info about this).
		 * Another solution (maybe simpler, maybe not) would have been to re-write
		 * the setup done by Process and manually call posix_spawn. The source
		 * code of the Process class is here: https://github.com/apple/swift-corelibs-foundation/blob/main/Sources/Foundation/Process.swift */
		
		/* The socket to send the fd */
		let sv = UnsafeMutablePointer<Int32>.allocate(capacity: 2)
		defer {sv.deallocate()}
		guard socketpair(AF_UNIX, SOCK_DGRAM, 0, sv) == 0 else {
			perror("Cannot create socket pair before launching xcodebuild")
			throw Errno(rawValue: errno)
		}
		
		let xcodebuildProcess = Process()
		xcodebuildProcess.standardInput = FileHandle(fileDescriptor: sv.advanced(by: 1).pointee, closeOnDealloc: true)
		xcodebuildProcess.executableURL = execBaseURL.appendingPathComponent("xct")
		xcodebuildProcess.arguments = [
			"internal-fd-get-launcher", "/usr/bin/xcodebuild",
			"-resultBundlePath", resultBundlePath,
			"-resultStreamPath", resultStreamPath
		]
		
		try xcodebuildProcess.run()
		
		try send(fd: fdXcodeWriteOutput, to: sv.pointee)
		
		if #available(OSX 10.15.4, *) {
			try print(String(data: pipe.fileHandleForReading.readData(ofLength: 7), encoding: .utf8))
		} else {
			fatalError("old os")
		}
		xcodebuildProcess.waitUntilExit()
	}
	
	/* https://stackoverflow.com/a/28005250 (last variant) */
	private func send(fd: Int32, to socket: Int32) throws {
		var fd = fd /* Because we use a pointer to it at some point, but never actually modified */
		
		var msg = msghdr()
		let bufSize = XCT_CMSG_SPACE(MemoryLayout.size(ofValue: fd))
		
		/* I don’t think it’s possible to allocate on the stack w/ Swift… */
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
			/* TODO: Use an actual error */
			throw ExitCode(rawValue: 1)
		}
		cmsg.pointee.cmsg_level = SOL_SOCKET
		cmsg.pointee.cmsg_type = SCM_RIGHTS
		cmsg.pointee.cmsg_len = socklen_t(XCT_CMSG_LEN(MemoryLayout.size(ofValue: fd)))
		
		memmove(XCT_CMSG_DATA(cmsg), &fd, MemoryLayout.size(ofValue: fd))
		print("yo: \(fd)")
		
		msg.msg_controllen = socklen_t(XCT_CMSG_SPACE(MemoryLayout.size(ofValue: fd)))
		
		guard sendmsg(socket, &msg, 0) >= 0 else {
			/* TODO: Use an actual error */
			throw ExitCode(rawValue: 1)
		}
	}
	
}

XctBuild.main()
