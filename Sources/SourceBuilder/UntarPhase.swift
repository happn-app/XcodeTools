import Foundation

import SignalHandling
import SystemPackage
import Utils
import XcodeTools



public struct UntarPhase : BuildPhase {
	
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
			Conf.logger?.warning("Strip components lower than 0 (\(stripComponents)). Ignoring.")
		}
		if verifyNoLostFilesFromStrip && stripComponents <= 0 {
			Conf.logger?.warning("Asked to verify loss of files from strip, but not stripping.")
		}
		if verifyNoLostFilesFromStrip && stripComponents > 0 {
//			var streamError: Error?
			var iterator = try ProcessRawOutputIterator("tar", args: ["--list", "--file", unarchivedFile.string], usePATH: true)
			while let l = try await iterator.next() {
				let lineStr = try l.utf8Line
				Conf.logger?.debug("got line (fd=\(l.fd.rawValue)): \(lineStr)")
				if lineStr.contains("NOOP") {break}
			}
//			try await Process.checkedSpawnAndStream("tar", args: ["--list", "--file", unarchivedFile.string], usePATH: true, outputHandler: { lineData, _, sourceFd, signalEOI, _ in
//				guard let lineStr = String(data: lineData, encoding: .utf8) else {
//					streamError = Err.nonUtf8Output(lineData)
//					return signalEOI()
//				}
//				guard sourceFd == .standardOutput else {
//					Conf.logger?.error("got line from fd \(sourceFd) of tar: \(lineStr)")
//					return
//				}
//				if lineStr.contains("NOOP") {return signalEOI()}
//				Conf.logger?.debug("got \(lineStr)")
//				return
//			})
//			try streamError?.throw()
		}
		throw Err.notImplemented
	}
	
}
