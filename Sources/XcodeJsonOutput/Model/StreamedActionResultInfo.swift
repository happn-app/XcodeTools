import Foundation



struct StreamedActionResultInfo : _Object {
	
	static var type: ObjectType = .init(name: "StreamedActionResultInfo")
	
	init(dictionary: [String : Any?]) throws {
		try Self.validateTypeFor(dictionary: dictionary)
		
		guard
			dictionary.count == 1
		else {
			throw Err.malformedObject
		}
	}
	
}
