import Foundation

import SystemPackage



public struct RawLineWithSource : Equatable, Hashable {
	
	public var line: Data
	public var eol: Data
	
	public var fd: FileDescriptor
	
	public func strLineWithSource(encoding: String.Encoding) throws -> LineWithSource {
		return try LineWithSource(line: strLine(encoding: encoding), eol: strEOL(encoding: encoding), fd: fd)
	}
	
	public func strLine(encoding: String.Encoding) throws -> String {
		return try String(data: line, encoding: encoding).get(orThrow: Err.invalidDataEncoding(line))
	}
	
	public func strEOL(encoding: String.Encoding) throws -> String {
		return try String(data: eol, encoding: encoding).get(orThrow: Err.invalidDataEncoding(line))
	}
	
}


public struct LineWithSource : Equatable, Hashable {
	
	public var line: String
	public var eol: String
	
	public var fd: FileDescriptor
	
}
