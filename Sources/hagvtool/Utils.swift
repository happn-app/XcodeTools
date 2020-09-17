import Foundation



extension String {
	
	func bracketEscaped() -> String {
		return self
			.replacingOccurrences(of: "\\", with: "\\\\", options: .literal)
			.replacingOccurrences(of: "[", with: "\\[", options: .literal)
			.replacingOccurrences(of: "]", with: "\\]", options: .literal)
			.replacingOccurrences(of: "*", with: "\\*", options: .literal)
	}
	
	func quoteEscaped() -> String {
		return self
			.replacingOccurrences(of: "\\", with: "\\\\", options: .literal)
			.replacingOccurrences(of: "\"", with: "\\\"", options: .literal)
	}
	
}
