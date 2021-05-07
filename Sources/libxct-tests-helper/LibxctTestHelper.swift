import Foundation

import ArgumentParser



@main
struct LibxctTestHelper : ParsableCommand {
	
	static var configuration = CommandConfiguration(
		subcommands: [
			SleepInSubprocess.self
		]
	)
	
}
