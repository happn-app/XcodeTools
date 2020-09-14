import ArgumentParser
import Foundation



enum OutputFormat : String, ExpressibleByArgument {
	
	case text
	case json
	case jsonPrettyPrinted
	
}
