import Foundation

import ArgumentParser
import CLTLogger
import Logging



struct XctBuild : ParsableCommand {
	
	static var configuration = CommandConfiguration(
		abstract: "Build an Xcode project",
		discussion: "Hopefully, the options supported by this tool are easier to understand than xcodebuild’s."
	)
	
	func run() throws {
		LoggingSystem.bootstrap{ _ in CLTLogger(messageTerminator: "\n") }
		let logger = Logger(label: "main")
		
		
	}
	
}

XctBuild.main()
