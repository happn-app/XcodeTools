import CryptoKit
import Foundation

import XcodeTools



//struct TarballUrlRetriever : SourceRetriever {
//
//	typealias RemoteSource = TarballUrl
//
//	func extractAndHash<H>(remoteSource: TarballUrl, cacheFolder: FilePath, destinationFolder: FilePath, hasher: H) async throws -> (Source, H.Digest) where H : HashFunction {
//	}
//
//	func ensureDownloaded() async throws {
//		if Config.fm.fileExists(atPath: localPath.string), try checkShasum(path: localPath) {
//			/* File exists and already has correct checksum (or checksum is not checked) */
//			Config.logger.info("Reusing downloaded tarball at path \(localPath)")
//		} else {
//			Config.logger.info("Downloading tarball from \(url)")
//			let (tmpFileURL, urlResponse) = try await URLSession.shared.download(from: url, delegate: nil)
//			guard let httpURLResponse = urlResponse as? HTTPURLResponse, 200..<300 ~= httpURLResponse.statusCode else {
//				struct InvalidURLResponse : Error {var response: URLResponse}
//				throw InvalidURLResponse(response: urlResponse)
//			}
//			/* At some point in the future, FilePath(tmpFileURL) will be possible
//			 * (it is already possible when importing System instead of
//			 * SystemPackage actually). This init might return nil, so the
//			 * tmpFilePath variable would have to be set in the guard above. */
//			assert(tmpFileURL.isFileURL)
//			let tmpFilePath = FilePath(tmpFileURL.path)
//			guard try checkShasum(path: tmpFilePath) else {
//				struct InvalidChecksumForDownloadedTarball : Error {}
//				throw InvalidChecksumForDownloadedTarball()
//			}
//			try Config.fm.ensureFileDeleted(path: localPath)
//			try Config.fm.moveItem(at: tmpFileURL, to: localPath.url)
//			Config.logger.info("Tarball downloaded")
//		}
//	}
//
//	func extract(in folder: FilePath) async throws -> FilePath {
//		try Config.fm.ensureDirectory(path: folder)
//		try Process.spawnAndStreamEnsuringSuccess("/usr/bin/tar", args: ["xf", localPath.string, "-C", folder.string], outputHandler: Process.logProcessOutputFactory())
//
//		var isDir = ObjCBool(false)
//		let extractedTarballDir = folder.appending(stem)
//		guard Config.fm.fileExists(atPath: extractedTarballDir.string, isDirectory: &isDir), isDir.boolValue else {
//			struct ExtractedTarballNotFound : Error {var expectedPath: FilePath}
//			throw ExtractedTarballNotFound(expectedPath: extractedTarballDir)
//		}
//		return extractedTarballDir
//	}
//
//	private func checkShasum(path: FilePath) async throws -> Bool {
//		guard let expectedShasum = expectedShasum else {
//			return true
//		}
//
//		let fileContents = try Data(contentsOf: path.url)
//		return SHA256.hash(data: fileContents).reduce("", { $0 + String(format: "%02x", $1) }) == expectedShasum.lowercased()
//	}
//
//}
