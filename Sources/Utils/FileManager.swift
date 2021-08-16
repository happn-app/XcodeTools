import Foundation

import SystemPackage



public extension FileManager {
	
	func ensureDirectory(path: FilePath) throws {
		var isDir = ObjCBool(false)
		if !fileExists(atPath: path.string, isDirectory: &isDir) {
			try createDirectory(at: path.url, withIntermediateDirectories: true, attributes: nil)
		} else {
			guard isDir.boolValue else {
				struct ExpectedDir : Error {var path: FilePath}
				throw ExpectedDir(path: path)
			}
		}
	}
	
	func ensureDirectoryDeleted(path: FilePath) throws {
		var isDir = ObjCBool(false)
		if fileExists(atPath: path.string, isDirectory: &isDir) {
			guard isDir.boolValue else {
				struct ExpectedDir : Error {var path: FilePath}
				throw ExpectedDir(path: path)
			}
			try removeItem(at: path.url)
		}
	}
	
	func ensureFileDeleted(path: FilePath) throws {
		var isDir = ObjCBool(false)
		if fileExists(atPath: path.string, isDirectory: &isDir) {
			guard !isDir.boolValue else {
				struct ExpectedFile : Error {var path: FilePath}
				throw ExpectedFile(path: path)
			}
			try removeItem(at: path.url)
		}
	}
	
	/**
	 Call the handler with the files. If the handler returns false, the iteration
	 is stopped. */
	func iterateFiles(in folder: FilePath, exclude: [NSRegularExpression], handler: (_ fullPath: FilePath, _ relativePath: FilePath, _ isDirectory: Bool) -> Bool) throws {
		let folder = folder.lexicallyNormalized()
		guard let enumerator = enumerator(at: folder.url, includingPropertiesForKeys: [.isDirectoryKey]) else {
			struct CannotCreateEnumerator : Error {var path: FilePath}
			throw CannotCreateEnumerator(path: folder)
		}
		
		for nextObject in enumerator {
			guard let url = nextObject as? URL, let path = FilePath(url) else {
				struct EnumeratorReturnedInvalidObject : Error {var enumeratedPath: FilePath; var returnedObject: Any}
				throw EnumeratorReturnedInvalidObject(enumeratedPath: folder, returnedObject: nextObject)
			}
			let fullPath = folder.pushing(path).lexicallyNormalized()
			var relativePath = fullPath
			guard relativePath.removePrefix(folder) else {
				struct EnumeratorReturnedAnURLOutsideOfRootFolder : Error {var enumeratedPath: FilePath; var returnedPath: FilePath}
				throw EnumeratorReturnedAnURLOutsideOfRootFolder(enumeratedPath: folder, returnedPath: path)
			}
			let relativePathString = relativePath.string
			guard !exclude.contains(where: { $0.rangeOfFirstMatch(in: relativePathString, range: NSRange(relativePathString.startIndex..<relativePathString.endIndex, in: relativePathString)).location != NSNotFound }) else {
				continue
			}
			guard let isDir = try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory else {
				struct CannotGetIsDirectory : Error {var enumeratedPath: FilePath; var currentPath: FilePath}
				throw CannotGetIsDirectory(enumeratedPath: folder, currentPath: relativePath)
			}
			guard handler(fullPath, relativePath, isDir) else {return}
		}
	}
	
}
