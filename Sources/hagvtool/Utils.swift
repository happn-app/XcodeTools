import Foundation



extension String {
	
	func bracketEscaped() -> String {
		return replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "[", with: "\\[").replacingOccurrences(of: "]", with: "\\]")
	}
	
}
