import Foundation



public protocol AnyActivityLogSectionTail : Object {
	
	var duration: Double {get}
	var result: String {get}
	
}

protocol _AnyActivityLogSectionTail : _Object, AnyActivityLogSectionTail {
}
