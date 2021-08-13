import Foundation

import XibLoc



public struct TarballUrl {
	
	public var url: URL
	
	public init(url: URL) {
		self.url = url
	}
	
	public init?(template: String, version: String) {
		/* The force-unwrap is valid: all the tokens are valid */
		let xibLocInfo = Str2StrXibLocInfo(simpleSourceTypeReplacements: [OneWordTokens(leftToken: "{{", rightToken: "}}"): { _ in version }], identityReplacement: { $0 })!
		let tarballStringURL = template.applying(xibLocInfo: xibLocInfo)
		guard let url = URL(string: tarballStringURL) else {
			return nil
		}
		self.url = url
	}
	
}
