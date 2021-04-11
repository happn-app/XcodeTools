import Foundation



/** This type is used when serializing a PBXObject */
struct ValueAndComment {
	
	var value: String
	var comment: String?
	
	func asString() -> String {
		return value.escapedForPBXProjValue() + (comment.flatMap{ " /* \($0) */" } ?? "")
	}
	
}
