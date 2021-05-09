#!/usr/bin/env swift

import Foundation



guard
	CommandLine.argc == 3,
	let nLines = Int(CommandLine.arguments[1]),
	let fd = Int32(CommandLine.arguments[2])
else {
	FileHandle.standardError.write(Data("usage: \(CommandLine.arguments[0]) nlines fd\n".utf8))
	exit(1)
}


let fh = FileHandle(fileDescriptor: fd)
for _ in 0..<nLines {
	Thread.sleep(forTimeInterval: 0.01)
	guard let _ = try? fh.write(contentsOf: Data("I will not leave books on the ground.\n".utf8)) else {
		FileHandle.standardError.write(Data("cannot write to fd \(fd)\n".utf8))
		exit(1)
	}
}
