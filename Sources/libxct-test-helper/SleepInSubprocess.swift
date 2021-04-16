import Foundation

import ArgumentParser
import CLTLogger
import Logging

import libxct
import SignalHandling



struct SleepInSubprocess : ParsableCommand {
	
	func run() throws {
		LoggingSystem.bootstrap{ _ in CLTLogger() }
		var logger = Logger(label: "main"); logger.logLevel = .trace
		SignalHandlingConfig.logger = logger
		LibXctConfig.logger = logger
		
		let (p, g) = try Process.spawnedAndStreamedProcess("/bin/sleep", args: ["424242"], outputHandler: { _,_ in })
		print(p.processIdentifier)
		p.waitUntilExit()
		g.wait()
	}
	
}
