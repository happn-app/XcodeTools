#!/usr/bin/env swift

import Foundation



@discardableResult
func shell(_ args: String...) -> (Int32, Process.TerminationReason, Data?, Data?) {
//	let stdoutPipe = Pipe()
//	let stderrPipe = Pipe()
	
	let task = Process()
	task.launchPath = "/usr/bin/env"
	task.arguments = args
//	task.standardOutput = stdoutPipe
//	task.standardError = stderrPipe
	task.launch()
	task.waitUntilExit()
	
	let stdout: Data? = nil//try? stdoutPipe.fileHandleForReading.readToEnd()
	let stderr: Data? = nil//try? stderrPipe.fileHandleForReading.readToEnd()
	return (task.terminationStatus, task.terminationReason, stdout, stderr)
}


FileManager.default.changeCurrentDirectoryPath(URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().path)
shell(
	"xcrun", "momc",
	"--action", "generate", "--swift-version", "5",
	"--macosx-deployment-target", "10.15",
	"--module", "XcodeTools_XcodeProj",
	"\(FileManager.default.currentDirectoryPath)/Sources/XcodeProj/PBXModel.xcdatamodeld",
	"/Users/frizlab/Downloads/toto/"
)
shell(
	"xcrun", "momc",
	"--action", "compile",
	"--macosx-deployment-target", "10.15",
	"--module", "XcodeTools_XcodeProj",
	"\(FileManager.default.currentDirectoryPath)/Sources/XcodeProj/PBXModel.xcdatamodeld",
	"/Users/frizlab/Downloads/toto/"
)
