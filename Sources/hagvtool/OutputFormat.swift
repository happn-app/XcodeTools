import ArgumentParser
import Foundation



enum OutputFormat : String, ExpressibleByArgument {
	
	case none
	case text
	case json
	case jsonPrettyPrinted = "json-pretty-printed"
	
}
