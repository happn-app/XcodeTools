import CryptoKit
import Foundation

import SystemPackage
import Utils
import XibLoc



public struct DownloadFilePhase : BuildPhase {
	
	public var downloadedURL: URL
	public var downloadDestination: FilePath
	
	public var expectedHash: (value: String, hasher: AnyHasher)?
	
	public var outputs: [FilePath] {
		return [downloadDestination]
	}
	
	public init(root: FilePath, inputs: [FilePath], arguments: [String: Any]) throws {
		throw Err.notImplemented
	}
	
	public init(urlTemplate template: String, variables: [String: String], destination: FilePath, expectedHash: (value: String, hasher: AnyHasher)?) throws {
		var unknownVars = Set<String>()
		let variableReplacementBlock: (String) -> String = { str in
			let varName = str.trimmingCharacters(in: .whitespacesAndNewlines)
			guard let val = variables[varName] else {
				unknownVars.insert(varName)
				return ""
			}
			return val
		}
		/* The force-unwrap is valid: all the tokens are valid */
		let xibLocInfo = Str2StrXibLocInfo(simpleSourceTypeReplacements: [OneWordTokens(leftToken: "{{", rightToken: "}}"): variableReplacementBlock], identityReplacement: { $0 })!
		let stringURL = template.applying(xibLocInfo: xibLocInfo)
		guard unknownVars.isEmpty else {
			throw Err.unknownVariablesInURLTemplate(unknownVars)
		}
		guard let url = URL(string: stringURL) else {
			throw Err.invalidURL(stringURL)
		}
		
		self.init(downloadedURL: url, destination: destination, expectedHash: expectedHash)
	}
		
	public init(downloadedURL: URL, destination: FilePath, expectedHash: (value: String, hasher: AnyHasher)?) {
		self.downloadedURL = downloadedURL
		self.downloadDestination = destination
		
		self.expectedHash = expectedHash
	}
	
	public var canBeSkipped: Bool {
		get async throws {
			guard Conf.fm.fileExists(atPath: downloadDestination.string) else {
				return false
			}
			let hash = try await expectedHash?.hasher.hash(of: downloadDestination)
			guard hash == expectedHash?.value else {
				return false
			}
			return true
		}
	}
	
	public func execute() async throws -> [FilePath] {
		Conf.logger?.info("Downloading file from \(downloadedURL)")
		let (tmpFileURL, urlResponse) = try await Conf.urlSession.download(from: downloadedURL, delegate: nil)
		guard let httpURLResponse = urlResponse as? HTTPURLResponse, 200..<300 ~= httpURLResponse.statusCode else {
			throw Err.invalidURLResponse(urlResponse)
		}
		/* At some point in the future, FilePath(tmpFileURL) will be possible (it
		 * is already possible when importing System instead of SystemPackage
		 * actually). This init might return nil, so the tmpFilePath variable
		 * would have to be set in the guard above. */
		assert(tmpFileURL.isFileURL)
		let tmpFilePath = FilePath(tmpFileURL.path)
		if let expectedHash = expectedHash {
			let hash = try await expectedHash.hasher.hash(of: tmpFilePath)
			guard hash == expectedHash.value else {
				throw Err.invalidChecksumForDownloadedFile(downloadedURL, expectedHash.value)
			}
		}
		try Conf.fm.ensureFileDeleted(path: downloadDestination)
		try Conf.fm.moveItem(at: tmpFileURL, to: downloadDestination.url)
		Conf.logger?.info("File downloaded")
		return [downloadDestination]
	}
	
}
