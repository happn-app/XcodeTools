import Foundation

import CLTLogger



struct IssueEmittedEventPayload : _AnyStreamedEventPayload {
	
	static var type: ObjectType = .init(name: "IssueEmittedEventPayload", supertype: .init(name: "AnyStreamedEventPayload"))
	
	var issue: IssueSummary
	var resultInfo: StreamedActionResultInfo
	var severity: String
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.issue      = try dictionary.getParsedAndRemove("issue")
		self.resultInfo = try dictionary.getParsedAndRemove("resultInfo")
		self.severity   = try dictionary.getParsedAndRemove("severity")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
	func humanReadableEvent(withColors: Bool) -> String? {
		let colorTagStart: String
		let colorTagEnd: String
		if withColors {
			switch severity {
				case "error":   colorTagStart = SGR(.fgColorTo4BitBrightRed).rawValue
				case "warning": colorTagStart = SGR(.fgColorTo4BitBrightMagenta).rawValue
				default:        colorTagStart = ""
			}
			colorTagEnd = (colorTagStart.isEmpty ? "" : SGR.reset.rawValue)
		} else {
			colorTagStart = ""
			colorTagEnd = ""
		}
		return colorTagStart + issue.issueType + colorTagEnd + ": " + issue.message
	}
	
}
