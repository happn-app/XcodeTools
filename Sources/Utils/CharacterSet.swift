import Foundation



public extension CharacterSet {
	
	static let asciiNum = CharacterSet(charactersIn: "0123456789")
	static let asciiAlpha = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
	static let asciiAlphanum = asciiAlpha.union(asciiNum)
	
}
