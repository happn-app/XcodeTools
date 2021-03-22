import Foundation

import ArgumentParser
import CMacroExports
import SystemPackage



struct InternalFdGetLauncher : ParsableCommand {
	
	static var configuration = CommandConfiguration(
		abstract: "Internal launcher for xct which receives a fd before launching the tool."
	)
	
	@Argument
	var toolName: String
	
	@Argument(parsing: .unconditionalRemaining)
	var toolArguments: [String] = []
	
	func run() throws {
		let fd = FileHandle.standardInput.fileDescriptor
		let xcodeFd = try receiveFd(from: fd)
		print(xcodeFd)
		
		try withCStrings([toolName] + toolArguments, scoped: { cargs in
			/* The v means we pass an array to exec (as opposed to the variadic
			 * exec variant, which is not available in Swift anyway). */
			let ret = execv(toolName, cargs)
			assert(ret != 0, "exec should not return if it was successful.")
			Xct.logger.error("Error running executable \(toolName): \(Errno(rawValue: errno).description)")
			throw ExitCode(errno)
		})
		
		fatalError("Unreachable code reached")
	}
	
	/* https://stackoverflow.com/a/28005250 (last variant) */
	private func receiveFd(from socket: Int32) throws -> Int32 {
		var msg = msghdr()
		
		/* The struct iovec is needed, even if it points to minimal data. */
		let ioBufSize = 1
		let ioBuf = UnsafeMutablePointer<Int8>.allocate(capacity: ioBufSize)
		defer {ioBuf.deallocate()}
		ioBuf.assign(repeating: 0, count: ioBufSize)
		
		let ioPtr = UnsafeMutablePointer<iovec>.allocate(capacity: 1)
		defer {ioPtr.deallocate()}
		ioPtr.initialize(to: iovec(iov_base: ioBuf, iov_len: ioBufSize))
		
		msg.msg_iov = ioPtr
		msg.msg_iovlen = 1
		
		let controlBufSize = 256
		let controlBuf = UnsafeMutablePointer<Int8>.allocate(capacity: controlBufSize)
		defer {controlBuf.deallocate()}
		controlBuf.assign(repeating: 0, count: ioBufSize)
		msg.msg_control = UnsafeMutableRawPointer(controlBuf)
		msg.msg_controllen = socklen_t(controlBufSize)
		
		guard recvmsg(socket, &msg, 0) >= 0 else {
			/* TODO: Use an actual error */
			throw ExitCode(rawValue: 1)
		}
		
		let cmsg = XCT_CMSG_FIRSTHDR(&msg)
		
		var fd: Int32 = -1
		memmove(&fd, XCT_CMSG_DATA(cmsg), MemoryLayout.size(ofValue: fd))
		return fd
	}
	
}
