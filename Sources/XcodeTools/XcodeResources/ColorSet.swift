import Foundation



public struct ColorSet {
	
	public var url: URL
	
	public var colorName: String {
		url.deletingPathExtension().lastPathComponent
	}
	
	public init?(url: URL) {
		/* TODO: More colorset validation (check json inside, etc.) */
		guard url.pathExtension.lowercased() == "colorset" else {
			return nil
		}
		self.url = url
	}
	
}
