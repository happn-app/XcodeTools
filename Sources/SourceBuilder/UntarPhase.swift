import Foundation

import SignalHandling
import SystemPackage
import Utils
import XcodeTools



public struct UntarPhase : BuildPhase {
	
	public enum Err : Error {
		
		case notImplemented
		
		case filepathHasNoExtensions(FilePath)
		case filepathHasNoStem(FilePath)
		
		/**
		 If the strip is applied to the given tar files, some files would be lost,
		 or written in the same folder though in different folders in the archive.
		 
		 The `filesLost` property contains the files whose path would completely
		 be ignored when tar extracts the archive because their path component is
		 too small.
		 
		 The `prefixes` property contains the different prefixes found for the
		 given strip count. If it contains more than one entry, some files would
		 be written in the same folder though they are in different folders in the
		 tar archive. */
		case stripWouldLoseFiles(filesLost: Set<FilePath>, prefixes: Set<FilePath>)
		
	}
	
	public var unarchivedFile: FilePath
	public var destinationFolder: FilePath
	
	/** `--keep-old-files` from (BSD) `tar` */
	public var keepOldFiles: Bool
	
	/** `--strip-components` from (BSD) `tar` */
	public var stripComponents: Int
	/**
	 Try and validate no files in the archive will be lost because of the strip
	 components option.
	 
	 This is done by first listing the files in the archive and verifying all of
	 the files are deep enough to be unarchived, and the dropped prefix is always
	 the same.
	 
	 For instance, if we have the following hierarchy:
	 ```
	 a.txt
	 b/b.txt
	 c/c.txt
	 ```
	 with a strip components set to 1, this option will flag the following files
	 as being lost and the action will throw when executed:
	 ```
	 a.txt   <- For obvious reasons, strip components would simply not extract it
	 c/c.txt <- Because the dropped prefix (c/) is not the same as for b/b.txt
	            This avoids losing folders
	 ``` */
	public var verifyNoLostFilesFromStrip: Bool
	
	public var outputs: [FilePath] {
		return [destinationFolder]
	}
	
	/* Even if the destination folder already exists, we cannot skip the tar
	 * unarchive as we don’t know if tar would modify the contents of the folder,
	 * and computing it would be almost as expensive as actually doing it. */
	public let canBeSkipped = false
	
	public init(root: FilePath, inputs: [FilePath], arguments: [String : Any]) throws {
		throw Err.notImplemented
	}
	
	/**
	 Uses the tar filename to determine the destination folder.
	 
	 The destination folder is the same path as the unarchived file, minus the
	 extension. If the unarchived file has two extension and the inner one is
	 “tar,” we remove it too. */
	public init(unarchivedFile: FilePath, keepOldFiles: Bool = true, stripComponents: Int = 0, verifyNoLostFilesFromStrip: Bool = false) throws {
		guard unarchivedFile.extension != nil else {
			throw Err.filepathHasNoExtensions(unarchivedFile)
		}
		guard let stem1 = unarchivedFile.stem.flatMap({ FilePath($0) }) else {
			throw Err.filepathHasNoStem(unarchivedFile)
		}
		let stem: String
		if stem1.extension == "tar", let s = stem1.stem {stem = s}
		else                                            {stem = stem1.string}
		self.init(unarchivedFile: unarchivedFile, destinationFolder: unarchivedFile.removingLastComponent().appending(stem), keepOldFiles: keepOldFiles, stripComponents: stripComponents, verifyNoLostFilesFromStrip: verifyNoLostFilesFromStrip)
	}
	
	public init(unarchivedFile: FilePath, destinationFolder: FilePath, keepOldFiles: Bool = true, stripComponents: Int = 0, verifyNoLostFilesFromStrip: Bool = false) {
		self.unarchivedFile = unarchivedFile
		self.destinationFolder = destinationFolder
		
		self.keepOldFiles = keepOldFiles
		
		self.stripComponents = stripComponents
		self.verifyNoLostFilesFromStrip = verifyNoLostFilesFromStrip
	}
	
	public func execute() async throws -> [FilePath] {
		if stripComponents < 0 {
			Conf.logger?.warning("Strip components lower than 0 (\(stripComponents)). Setting to 0.")
		}
		if verifyNoLostFilesFromStrip {
			if stripComponents <= 0 {
				Conf.logger?.warning("Asked to verify loss of files from strip, but not stripping.")
			} else {
				var prefixes = Set<FilePath>()
				var filesLost = Set<FilePath>()
				for try await l in ProcessInvocation("tar", "--list", "--file", unarchivedFile.string) {
					guard l.fd == .standardOutput else {
						Conf.logger?.warning("tar stderr: \(l.strLineOrHex(encoding: .utf8))")
						continue
					}
					let strLine = try l.strLine(encoding: .utf8)
					let isDir = strLine.hasSuffix("/") /* Sadly FilePath does not seem to be aware of this */
					let path = FilePath(strLine)
					if path.components.count <= stripComponents {
						if !isDir {
							filesLost.insert(path)
						}
					} else {
						let components = path.components
						let startIndex = components.startIndex
						let endIndex = components.index(startIndex, offsetBy: stripComponents)
						prefixes.insert(FilePath(root: path.root, components[startIndex..<endIndex]))
					}
				}
				guard filesLost.isEmpty, prefixes.count <= 1 else {
					throw Err.stripWouldLoseFiles(filesLost: filesLost, prefixes: prefixes)
				}
			}
		}
		throw Err.notImplemented
	}
	
}
