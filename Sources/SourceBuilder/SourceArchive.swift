import Foundation

import CryptoKit
import SystemPackage



public protocol SourceArchive {
	
	/** Extracts the given source in the given destinationFolder, optionally
	 using a cache. */
	func extractAndHash<H : HashFunction>(cacheFolder: FilePath?, destinationFolder: FilePath, hasher: H) async throws -> (Source, H.Digest)
	
}
