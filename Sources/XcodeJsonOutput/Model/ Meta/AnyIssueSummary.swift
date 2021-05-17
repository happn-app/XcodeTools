import Foundation



public protocol AnyIssueSummary : Object {
	
	var issueType: String {get}
	var message: String {get}
	
}


protocol _AnyIssueSummary : _Object, AnyIssueSummary {
}
