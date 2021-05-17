import Foundation



public protocol AnyStreamedEventPayload : Object {
	
	func humanReadableEvent(withColors: Bool) -> String?
	
}


protocol _AnyStreamedEventPayload : _Object, AnyStreamedEventPayload {
}
