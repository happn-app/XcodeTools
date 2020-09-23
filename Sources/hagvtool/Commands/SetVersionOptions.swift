import Foundation

import ArgumentParser



struct SetVersionOptions : ParsableArguments {
	
	enum InvalidSetupBehaviour : String, ExpressibleByArgument {
		
		case fail
		case fix
		
	}
	
	@Option
	var invalidSetupBehaviour = InvalidSetupBehaviour.fail
	
}
