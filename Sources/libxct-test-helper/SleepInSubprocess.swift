import Foundation

import ArgumentParser
import CLTLogger
import Logging

import libxct
import SignalHandling



struct SleepInSubprocess : ParsableCommand {
	
	static var logger: Logger?
	
	func run() throws {
//		try SigactionDelayer_Block.bootstrap(for: Signal.toForwardToSubprocesses)
		LoggingSystem.bootstrap{ _ in CLTLogger() }
		
		var logger = Logger(label: "main")
		logger.logLevel = .trace
		SleepInSubprocess.logger = logger /* We must do this to be able to use the logger from the C handler. */
		LibXctConfig.logger?.logLevel = .trace
		SignalHandlingConfig.logger?.logLevel = .trace
		
		try Sigaction(handler: .ansiC({ _ in SleepInSubprocess.logger?.debug("In libxct-test-helper sigaction handler for interrupt") })).install(on: .interrupt)
		try Sigaction(handler: .ansiC({ _ in SleepInSubprocess.logger?.debug("In libxct-test-helper sigaction handler for terminated") })).install(on: .terminated)
		
		let s = DispatchSource.makeSignalSource(signal: Signal.terminated.rawValue)
		s.setEventHandler(handler: { SleepInSubprocess.logger?.debug("In libxct-test-helper dispatch source handler for terminated") })
		s.activate()
		
		let (p, g) = try Process.spawnedAndStreamedProcess("/bin/sleep", args: ["424242"]/*, signalsToForward: [.userDefinedSignal1]*/, outputHandler: { _,_ in })
		logger.info("Sub-process launched w/ PID \(p.processIdentifier)")
		
		for _ in 0..<0 {
			sleep(1)
			logger.info("Sending signal 15 to myself")
			kill(getpid(), 15)
		}
		
		p.waitUntilExit()
		g.wait()
	}
	
}
