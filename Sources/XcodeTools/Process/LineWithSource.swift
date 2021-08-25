import Foundation

import SystemPackage



public struct RawLineWithSource : Equatable, Hashable {
	
	public var line: Data
	public var eol: Data
	
	public var fd: FileDescriptor
	
	public var lineWithSource: LineWithSource {
		get throws {
			return try LineWithSource(line: utf8Line, eol: utf8EOL, fd: fd)
		}
	}
	
	public var utf8Line: String {
		get throws {
			return try String(data: line, encoding: .utf8).get(orThrow: Err.nonUtf8Output(line))
		}
	}
	
	public var utf8EOL: String {
		get throws {
			return try String(data: eol, encoding: .utf8).get(orThrow: Err.nonUtf8Output(line))
		}
	}
	
}


public struct LineWithSource : Equatable, Hashable {
	
	public var line: String
	public var eol: String
	
	public var fd: FileDescriptor
	
}
