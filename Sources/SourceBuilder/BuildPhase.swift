import Foundation

import SystemPackage



protocol BuildPhase {
	
	var inputs: [FilePath] {get set}
	var outputs: [FilePath] {get}
	
}
