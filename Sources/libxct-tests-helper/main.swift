import Foundation

import ArgumentParser



struct LibxctTestHelper : ParsableCommand {
	
	static var configuration = CommandConfiguration(
		subcommands: [
			SleepInSubprocess.self
		]
	)
	
}

LibxctTestHelper.main()
