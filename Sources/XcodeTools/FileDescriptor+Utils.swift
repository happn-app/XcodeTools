import Foundation

import SystemPackage



extension FileDescriptor {
	
	/* These will be deprecated when they are included in SystemPackage */
	public static let xctStdin  = FileDescriptor(rawValue: FileHandle.standardInput.fileDescriptor)
	public static let xctStdout = FileDescriptor(rawValue: FileHandle.standardOutput.fileDescriptor)
	public static let xctStderr = FileDescriptor(rawValue: FileHandle.standardError.fileDescriptor)
	
}
