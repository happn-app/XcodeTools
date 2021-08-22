#!/usr/bin/swift
import Foundation

let envName = (CommandLine.argc == 2 ? CommandLine.arguments[1] : nil)

if let envName = envName {
	print(FileManager.default.currentDirectoryPath)
	print(getenv(envName).flatMap{ String(cString: $0) } ?? "<no value>")
} else {
	struct EnvAndCwd : Encodable {
		var cwd: String
		var env = [String: String]()
	}
	
	var curEnv = environ
	let encoder = JSONEncoder()
	var envAndCwd = EnvAndCwd(cwd: FileManager.default.currentDirectoryPath)
	
	while let curVarValC = curEnv.pointee {
		defer {curEnv = curEnv.advanced(by: 1)}
		let curVarVal = String(cString: curVarValC)
		let split = curVarVal.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
		assert(split.count == 2) /* If this assert is false, the environ variable is invalid. As we’re a test script we don’t care about being fully safe. */
		envAndCwd.env[split[0]] = split[1] /* Same, if we get the same var twice, environ is invalid so we override without worrying. */
	}
	print(try String(data: encoder.encode(envAndCwd), encoding: .utf8)!)

	/* This is the paranoid base64 version. */
//	while let curVarValC = curEnv.pointee {
//		defer {curEnv = curEnv.advanced(by: 1)}
//		let equalPosition = strstr(curVarValC, "=")! /* We assume environ is valid (and thus curVarValC properly 0-terminated, and contains at least one “=”) */
//		let varData = Data(bytes: curVarValC, count: curVarValC.distance(to: equalPosition))
//		let valData = Data(bytes: equalPosition.advanced(by: 1), count: strlen(equalPosition) - 1)
//		let varBase64 = varData.base64EncodedString()
//		let valBase64 = valData.base64EncodedString()
//		envAndCwd.env[varBase64] = valBase64
//	}
//	print(try encoder.encode(envAndCwd).base64EncodedString())
}
