import Foundation



/**
Represent a build setting key (string and parameters).

For example, for the following config: “`MY_CONFIG[sdk=*][arch=*]`”, the
`BuildSettingKey` would be:
```
   key = "MY_CONFIG"
   parameters = [("sdk", "*"), ("arch", "*")]
```

- Important:
No validation is done on the parameters, nor the key. */
public struct BuildSettingKey : Hashable {
	
	public struct BuildSettingKeyParam : Hashable {
		
		public var key: String
		public var value: String
		
	}
	
	public var key: String
	public var parameters: [BuildSettingKeyParam]
	
	public init(laxSerializedKey serializedKey: String, allowCommaSeparatorForParameters: Bool = false) {
		let scanner = Scanner(forParsing: serializedKey)
		key = scanner.scanUpToString("[") ?? ""
		parameters = BuildSettingKey.parseSettingParams(scanner: scanner, allowCommaSeparator: allowCommaSeparatorForParameters)
		if !scanner.isAtEnd {
			NSLog("%@", "Warning: Got build setting key which seems invalid (scanner not at end after parsing parameters). Raw key is: “\(serializedKey)”.")
		}
	}
	
	public init(serializedKey: String, allowCommaSeparatorForParameters: Bool = false) throws {
		let scanner = Scanner(forParsing: serializedKey)
		key = scanner.scanUpToString("[") ?? ""
		parameters = BuildSettingKey.parseSettingParams(scanner: scanner, allowCommaSeparator: allowCommaSeparatorForParameters)
		if !scanner.isAtEnd {
			throw HagvtoolError(message: "Got build setting which seems invalid (scanner not at end after parsing parameters). Raw key is: “\(serializedKey)”.")
		}
	}
	
	public init(key: String, parameters: [BuildSettingKeyParam] = []) {
		self.key = key
		self.parameters = parameters
	}
	
	/**
	Parses the parameter of a setting.
	
	Expects a scanner whose location is at the beginning of the parameters
	(open bracket). Example:
	```
	MY_BUILD_SETTING[skd=*]
	                ^ scanner location
	```
	
	At the end of the function, the scanner’s location will be at the end of the
	parameters (just after the closing bracket). Example:
	```
	MY_BUILD_SETTING[skd=*]
	                       ^ scanner location
	```
	
	In case of a parsing error, the scanner’s location will be put to the last
	successful parse location, and all successfully parsed parameters will be
	returned. Examples:
	```
	MY_BUILD_SETTING[skd=*][this_is_junk
	                       ^ scanner location
	   -> Returned parameters: [("sdk", "*")]
	MY_BUILD_SETTING[skd=*][arch=*,this_is_junk
	                       ^ scanner location
	   -> Returned parameters: [("sdk", "*")]
	```
	
	- parameter scanner: A scanner whose location is at the beginning of the
	parameters.
	- parameter allowCommaSeparator:
	https://pewpewthespells.com/blog/xcconfig_guide.html says the settings
	parameters can be separated by a comma, like so: `PARAMETER[sdk=*,arch=*]`,
	however my tests told me it does not work! (Xcode 12.0 beta 6 (12A8189n))
	You can reactivate parsing w/ the comma for tests if needed w/ this param. */
	static func parseSettingParams(scanner: Scanner, allowCommaSeparator: Bool) -> [BuildSettingKeyParam] {
		var first = true
		var success = true
		var lastSuccessParseIdx = scanner.currentIndex
		
		var parameters = [BuildSettingKeyParam]()
		var pendingParameters = [BuildSettingKeyParam]()
		while scanner.scanString("[") != nil || (allowCommaSeparator && !first && scanner.scanString(",") != nil) {
			let variantName = scanner.scanUpToString("=") ?? ""
			if scanner.scanString("=") == nil {
				scanner.currentIndex = lastSuccessParseIdx
				return parameters
			}
			
			let variantValue = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: allowCommaSeparator ? ",]" : "]")) ?? ""
			if scanner.scanString("]") != nil {
				parameters.append(contentsOf: pendingParameters)
				parameters.append(BuildSettingKeyParam(key: variantName, value: variantValue))
				lastSuccessParseIdx = scanner.currentIndex
				pendingParameters.removeAll()
				success = true
			} else {
				/* We are either on the comma separator (if allowed) or at the end
				 * of the string. If at the end of the string, this is an error,
				 * which will be caugth when we exit the loop and success is not
				 * true. If we’re on the comma separator, we continue the parsing. */
				pendingParameters.append(BuildSettingKeyParam(key: variantName, value: variantValue))
				success = false
			}
			
			first = false
		}
		if !success {
			scanner.currentIndex = lastSuccessParseIdx
		}
		return parameters
	}
	
}
