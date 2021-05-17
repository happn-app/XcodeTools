import Foundation



public protocol AnyActivityLogSectionHead : Object {
	
	var domainType: String {get}
	var startTime: Date {get}
	var title: String {get}
	
}


protocol _AnyActivityLogSectionHead : _Object, AnyActivityLogSectionHead {
}
