import Foundation

import ArgumentParser
import CLTLogger
import CMacroExports
import Logging
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
		Xct.logger.logLevel = .trace
		
		let fd = FileHandle.standardInput.fileDescriptor
		var fdDup = [CInt: CInt]()
		while let (receivedFd, expectedDestinationFd) = try receiveFd(from: fd) {
			Xct.logger.debug("fd received: \(receivedFd), \(expectedDestinationFd))")
			guard fdDup[expectedDestinationFd] == nil else {
				/* TODO: Use an actual error */
				throw ExitCode(rawValue: 1)
			}
			fdDup[expectedDestinationFd] = receivedFd
		}
		try FileDescriptor(rawValue: fd).close()
		
		#warning("TODO: Check overlapping fds…")
		for (destinationFd, fd) in fdDup {
			/* dup2 takes care of this case, but needed later. */
			guard destinationFd != fd else {continue}
			guard dup2(fd, destinationFd) != -1 else {
				/* TODO: Use an actual error */
				throw ExitCode(rawValue: 1)
			}
			guard close(fd) == 0 else {
				/* TODO: Use an actual error */
				throw ExitCode(rawValue: 1)
			}
		}
		
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
	private func receiveFd(from socket: CInt) throws -> (receivedFd: CInt, expectedDestinationFd: CInt)? {
		var msg = msghdr()
		
		/* We receive the destination fd (a simple CInt) in an iovec. */
		let iovBase = UnsafeMutablePointer<CInt>.allocate(capacity: 1)
		defer {iovBase.deallocate()}
		iovBase.initialize(to: -1)
		
		let ioPtr = UnsafeMutablePointer<iovec>.allocate(capacity: 1)
		defer {ioPtr.deallocate()}
		ioPtr.initialize(to: iovec(iov_base: iovBase, iov_len: MemoryLayout<CInt>.size))
		
		msg.msg_iov = ioPtr
		msg.msg_iovlen = 1
		
		/* Ancillary data. This is where we receive the actual fd. */
		let controlBufSize = 256
		let controlBuf = UnsafeMutablePointer<Int8>.allocate(capacity: controlBufSize)
		defer {controlBuf.deallocate()}
		controlBuf.assign(repeating: 0, count: controlBufSize)
		msg.msg_control = UnsafeMutableRawPointer(controlBuf)
		msg.msg_controllen = socklen_t(controlBufSize)
		
		let receivedBytes = recvmsg(socket, &msg, 0)
		guard receivedBytes >= 0 else {
			/* The socket is not a TCP socket, so we cannot know whether the
			 * connexion was closed before reading it. We check error after reading
			 * and ignore connection reset error. */
			let ok = (receivedBytes == 0 || errno == ECONNRESET)
			if ok {return nil}
			else  {/* TODO: Use an actual error */throw ExitCode(rawValue: 1)}
		}
		
		let expectedDestinationFd = iovBase.pointee
		
		var receivedFd: Int32 = -1
		let cmsg = XCT_CMSG_FIRSTHDR(&msg)
		memmove(&receivedFd, XCT_CMSG_DATA(cmsg), MemoryLayout.size(ofValue: receivedFd))
		
		guard receivedFd != -1, expectedDestinationFd != -1 else {
			/* TODO: Use an actual error (internal error) */
			throw ExitCode(rawValue: 1)
		}
		return (receivedFd: receivedFd, expectedDestinationFd: expectedDestinationFd)
	}
	
	/* If needed. From https://stackoverflow.com/a/12340767 */
	private func isValidFileDescriptor(_ fd: FileDescriptor) -> Bool {
		return fcntl(fd.rawValue, F_GETFL) != -1 || errno != EBADF
	}
	
}
