import Foundation

import ArgumentParser
import CLTLogger
import Logging

import libxct
import SignalHandling



struct SleepInSubprocess : ParsableCommand {
	
	static var logger: Logger?
	
	func run() throws {
		LoggingSystem.bootstrap{ _ in CLTLogger() }
		var logger = Logger(label: "main"); logger.logLevel = .trace
		SignalHandlingConfig.logger = logger
		LibXctConfig.logger = logger
		/* We must do this to be able to use the logger from the C handler. */
		SleepInSubprocess.logger = logger
		
		try SignalHandling.installSigaction(signal: .terminated, action: Sigaction(handler: .ansiC({ _ in SleepInSubprocess.logger?.debug("In libxct-test-helper sigaction handler for terminated") })))
		try SignalHandling.installSigaction(signal: .interrupt, action: Sigaction(handler: .ansiC({ _ in SleepInSubprocess.logger?.debug("In libxct-test-helper sigaction handler for interrupt") })))
		
		let (p, g) = try Process.spawnedAndStreamedProcess("/bin/sleep", args: ["424242"]/*, signalsToForward: [.userDefinedSignal1]*/, outputHandler: { _,_ in })
		logger.info("Sub-process launched w/ PID \(p.processIdentifier)")
		
		for _ in 0..<1 {
			sleep(1)
			logger.info("Sending signal 15 to myself")
			kill(getpid(), 15)
		}
		
		p.waitUntilExit()
		g.wait()
	}
	
}
