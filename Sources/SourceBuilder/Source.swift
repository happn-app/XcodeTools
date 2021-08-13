import Foundation

import SystemPackage



public struct Source {
	
	/** The path to the root of the source. Usually a folder, but if the program
	 contains a single file, it can be a file too. */
	public var root: FilePath
	
	public var version: String?
	
	public init(root: FilePath, version: String?) {
		self.root = root
		self.version = version
	}
	
}
