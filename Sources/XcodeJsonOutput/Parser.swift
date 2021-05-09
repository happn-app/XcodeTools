import Foundation

import Utils



public enum Parser {
	
	public static func parse(jsonString: String) throws -> Object {
		return try self.parse(json: Data(jsonString.utf8))
	}
	
	public static func parse(json: Data) throws -> Object {
		let jsonObject = try Result{ try JSONSerialization.jsonObject(with: json, options: []) }
			.mapErrorAndGet{ Err.invalidJSON($0) }
		guard let dictionary = jsonObject as? [String: Any?] else {
			throw Err.invalidJSONType
		}
		return try self.parse(dictionary: dictionary)
	}
	
	public static func parse(dictionary: [String: Any?]) throws -> Object {
		let objectType = try ObjectType(dictionary: dictionary)
		for type: _Object.Type in allObjectTypes {
			guard objectType == type.type else {continue}
			return try type.init(dictionary: dictionary)
		}
		throw Err.unknownObjectType(objectType.name)
	}
	
	static var allObjectTypes: [_Object.Type] = [
		ActivityLogCommandInvocationSectionHead.self,
		ActivityLogSectionHead.self,
		
		ActionStartedEventPayload.self,
		InvocationStartedEventPayload.self,
		LogMessageEmittedEventPayload.self,
		LogSectionAttachedEventPayload.self,
		LogSectionCreatedEventPayload.self,
		LogTextAppendedEventPayload.self,
		
		ActionDeviceRecord.self,
		ActionPlatformRecord.self,
		ActionRecordHead.self,
		ActionRunDestinationRecord.self,
		ActionSDKRecord.self,
		ActionsInvocationMetadata.self,
		ActivityLogMessage.self,
		EntityIdentifier.self,
		StreamedActionInfo.self,
		StreamedActionResultInfo.self,
		StreamedEvent.self,
		
		Bool.self,
		Date.self,
		Int.self,
		String.self
	]
	
	static func parsePayload(dictionary: [String: Any?]) throws -> AnyStreamedEventPayload {
		guard let object = try parse(dictionary: dictionary) as? AnyStreamedEventPayload else {
			throw Err.invalidObjectType
		}
		return object
	}
	
	static func parseActivityLogSectionHead(dictionary: [String: Any?]) throws -> AnyActivityLogSectionHead {
		guard let object = try parse(dictionary: dictionary) as? AnyActivityLogSectionHead else {
			throw Err.invalidObjectType
		}
		return object
	}
	
}
