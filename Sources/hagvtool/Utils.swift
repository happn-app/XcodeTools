import Foundation



extension String {
	
	func bracketEscaped() -> String {
		return self
			.replacingOccurrences(of: "\\", with: "\\\\")
			.replacingOccurrences(of: "[", with: "\\[")
			.replacingOccurrences(of: "]", with: "\\]")
			.replacingOccurrences(of: "*", with: "\\*")
	}
	
	func quoteEscaped() -> String {
		return self
			.replacingOccurrences(of: "\\", with: "\\\\")
			.replacingOccurrences(of: "\"", with: "\\\"")
	}
	
}
