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
		return try self.parse(dictionary: dictionary, parentPropertyName: nil)
	}
	
	public static func parse(dictionary: [String: Any?], parentPropertyName: String?) throws -> Object {
		let objectType = try ObjectType(dictionary: dictionary)
		for type: _Object.Type in allObjectTypes {
			guard objectType == type.type else {continue}
			return try type.init(dictionary: dictionary, parentPropertyName: parentPropertyName)
		}
		throw Err.unknownObjectType("\(objectType)", objectDictionary: dictionary)
	}
	
	static var allObjectTypes: [_Object.Type] = [
		ActivityLogCommandInvocationSectionHead.self,
		ActivityLogSectionHead.self,
		
		ActivityLogCommandInvocationSectionTail.self,
		ActivityLogSectionTail.self,
		
		ActionFinishedEventPayload.self,
		ActionStartedEventPayload.self,
		InvocationFinishedEventPayload.self,
		InvocationStartedEventPayload.self,
		IssueEmittedEventPayload.self,
		LogMessageEmittedEventPayload.self,
		LogSectionAttachedEventPayload.self,
		LogSectionClosedEventPayload.self,
		LogSectionCreatedEventPayload.self,
		LogTextAppendedEventPayload.self,
		
		IssueSummary.self,
		TestFailureIssueSummary.self,
		
		ActionDeviceRecord.self,
		ActionPlatformRecord.self,
		ActionRecordHead.self,
		ActionRecordTail.self,
		ActionResult.self,
		ActionRunDestinationRecord.self,
		ActionSDKRecord.self,
		ActionsInvocationMetadata.self,
		ActivityLogMessage.self,
		CodeCoverageInfo.self,
		DocumentLocation.self,
		EntityIdentifier.self,
		Reference.self,
		ResultIssueSummaries.self,
		ResultMetrics.self,
		StreamedActionInfo.self,
		StreamedActionResultInfo.self,
		StreamedEvent.self,
		TypeDefinition.self,
		
		Array<IssueSummary>.self,
		Array<TestFailureIssueSummary>.self,
		Bool.self,
		Date.self,
		Double.self,
		Int.self,
		String.self
	]
	
	static func parsePayload(dictionary: [String: Any?], parentPropertyName: String?) throws -> AnyStreamedEventPayload {
		guard let object = try parse(dictionary: dictionary, parentPropertyName: parentPropertyName) as? AnyStreamedEventPayload else {
			throw Err.invalidObjectType(parentPropertyName: parentPropertyName, expectedType: "AnyStreamedEventPayload", givenObjectDictionary: dictionary)
		}
		return object
	}
	
	static func parseActivityLogSectionHead(dictionary: [String: Any?], parentPropertyName: String?) throws -> AnyActivityLogSectionHead {
		guard let object = try parse(dictionary: dictionary, parentPropertyName: parentPropertyName) as? AnyActivityLogSectionHead else {
			throw Err.invalidObjectType(parentPropertyName: parentPropertyName, expectedType: "AnyActivityLogSectionHead", givenObjectDictionary: dictionary)
		}
		return object
	}
	
	static func parseActivityLogSectionTail(dictionary: [String: Any?], parentPropertyName: String?) throws -> AnyActivityLogSectionTail {
		guard let object = try parse(dictionary: dictionary, parentPropertyName: parentPropertyName) as? AnyActivityLogSectionTail else {
			throw Err.invalidObjectType(parentPropertyName: parentPropertyName, expectedType: "AnyActivityLogSectionTail", givenObjectDictionary: dictionary)
		}
		return object
	}
	
}
