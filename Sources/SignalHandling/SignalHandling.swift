import Foundation

import SystemPackage



public struct SignalHandling {
	
	public typealias OriginalHandlerAction = (_ signal: Signal, _ runOriginalActionHandler: (_ runOriginalAction: Bool) -> Void) -> Void
	
	public struct UnsigactionID : Hashable {
		
		private static var latestID = 0
		
		internal var id: Int
		internal var signal: Signal
		
		internal init(signal: Signal) {
			defer {Self.latestID += 1}
			self.id = Self.latestID
			self.signal = signal
		}
		
		public static func ==(_ lhs: UnsigactionID, _ rhs: UnsigactionID) -> Bool {
			return lhs.id == rhs.id
		}
		
		public func hash(into hasher: inout Hasher) {
			hasher.combine(id)
		}
		
	}
	
	/**
	Will force the current signal to be ignored from the sigaction PoV, and
	handle the signal using a `DispatchSourceSignal`.
	
	This is useful to use a `DispatchSourceSignal`, because GCD will not change
	the sigaction when creating the source, and thus, the sigaction _will be
	executed_ even if a dispatch source signal is setup for the given signal.
	
	**Example**: If you register a dispatch source signal for the signal 15 but
	does not ensure signal 15 is ignored, when you receive this signal your
	program will stop because the default handler for this signal is to quit.
	
	All unsigaction IDs must be released for the original sigaction to be set on
	the signal again.
	
	- Note: On Linux, the `DispatchSourceSignal` does change the `sigaction` for
	the signal: https://github.com/apple/swift-corelibs-libdispatch/pull/560
	That’s one more reason to unsigaction the signal before handling it with GCD. */
	public static func retainUnsigactionedSignal(_ signal: Signal, originalHandlerAction: @escaping OriginalHandlerAction) throws -> UnsigactionID {
		return try UnsigactionedSignal.signalProcessingQueue.sync{
			/* Whether the signal was retained before or not, we re-install the
			 * ignore handler on the given signal. */
			let oldSigaction = try installSigaction(signal: signal, action: .ignoreAction)
			
			let unsigactionID = UnsigactionID(signal: signal)
			
			var unsigactionedSignal: UnsigactionedSignal
			if let us = unsigactionedSignals[signal] {
				unsigactionedSignal = us
				if let oldSigaction = oldSigaction {
					/* The sigaction has been modified by someone else. We update our
					 * original sigaction to the new sigaction.
					 * Clients should not do that though. */
					unsigactionedSignal.originalSigaction = oldSigaction
					SignalHandlingConfig.logger?.warning("sigaction handler modified for an unsigactioned signal; the sigaction has been reset to ignore", metadata: ["signal": "\(signal)"])
				}
			} else {
				let dispatchSourceSignal = DispatchSource.makeSignalSource(signal: signal.rawValue, queue: UnsigactionedSignal.signalProcessingQueue)
				dispatchSourceSignal.setEventHandler{ [weak dispatchSourceSignal] in
					guard let dispatchSourceSignal = dispatchSourceSignal else {
						SignalHandlingConfig.logger?.error("INTERNAL ERROR: Event handler called, but dispatch source is nil", metadata: ["signal": "\(signal)"])
						return
					}
					SignalHandling.processSignalFromDispatch(signal: signal, count: dispatchSourceSignal.data)
				}
				dispatchSourceSignal.activate()
				unsigactionedSignal = UnsigactionedSignal(originalSigaction: oldSigaction ?? .ignoreAction, dispatchSource: dispatchSourceSignal)
			}
			
			assert(unsigactionedSignal.unsigactionInfo[unsigactionID] == nil)
			unsigactionedSignal.unsigactionInfo[unsigactionID] = originalHandlerAction
			unsigactionedSignals[signal] = unsigactionedSignal
			
			return unsigactionID
		}
	}
	
	/**
	Do **NOT** call this from the `originalHandlerAction` you give when
	unsigactioning a signal. */
	public static func releaseUnsigactionedSignal(_ id: UnsigactionID) throws {
		try UnsigactionedSignal.signalProcessingQueue.sync{
			guard var unsigactionedSignal = unsigactionedSignals[id.signal] else {
				/* We trust our source not to have an internal logic error. If the
				 * unsigactioned signal is not found, it is because the callee
				 * called release twice on the same unsigaction ID. */
				SignalHandlingConfig.logger?.error("Overrelease of unsigation", metadata: ["signal": "\(id.signal)"])
				return
			}
			assert(!unsigactionedSignal.unsigactionInfo.isEmpty, "INTERNAL ERROR: unsigactionInfo should never be empty because when it is, the whole unsigactioned signal should be removed.")
			
			guard unsigactionedSignal.unsigactionInfo.removeValue(forKey: id) != nil else {
				/* Same here. If the unsigaction ID was not in the unsigactionInfo,
				 * it can only be because the callee called release twice on the
				 * same ID. */
				SignalHandlingConfig.logger?.error("Overrelease of unsigation for signal: \(id.signal)")
				return
			}
			
			if !unsigactionedSignal.unsigactionInfo.isEmpty {
				/* We have nothing more to do except update the unsigactioned
				 * signals: there are more unsigaction that have been registered for
				 * this signal, so we cannot touch the sigaction handler. */
				unsigactionedSignals[id.signal] = unsigactionedSignal
				return
			}
			
			/* Now we have removed **all** unsigactions on the given signal. Let’s
			 * restore the signal to the state before unsigactions. */
			try installSigaction(signal: id.signal, action: unsigactionedSignal.originalSigaction)
			unsigactionedSignal.dispatchSource.cancel()
			
			/* Finally, once the sigaction has been restored to the original value,
			 * we can remove the unsigactioned signal from the list. */
			unsigactionedSignals.removeValue(forKey: id.signal)
		}
	}
	
	/**
	Convenience to unsigaction multiple signals in one function call.
	
	If one of the signal cannot be unsigactioned, the other signals that were
	successfully unsigactioned will be resigactioned. Of course this can fail
	too, in which case an error will be logged (but nothing more will be done). */
	public static func unsigactionSignals(_ signals: Set<Signal>, originalHandlerAction: @escaping OriginalHandlerAction) throws -> [Signal: UnsigactionID] {
		var ret = [Signal: UnsigactionID]()
		for signal in signals {
			do {
				ret[signal] = try retainUnsigactionedSignal(signal, originalHandlerAction: originalHandlerAction)
			} catch {
				for (signal, UnsigactionID) in ret {
					do    {try releaseUnsigactionedSignal(UnsigactionID)}
					catch {SignalHandlingConfig.logger?.error("Cannot release unsigactioned signal \(signal) in recovery handler of unsigactionSignals. The signal will stay ignored, probably forever.")}
				}
				throw error
			}
		}
		return ret
	}
	
	/**
	Check if the given signal is ignored using `sigaction`. */
	public static func isSignalIgnored(_ signal: Signal) throws -> Bool {
		return try Sigaction(rawValue: sigactionFrom(signal: signal)).handler == .ignoreHandler
	}
	
	/**
	Check if the given signal is handled with default action using `sigaction`. */
	public static func isSignalDefaultAction(_ signal: Signal) throws -> Bool {
		return try Sigaction(rawValue: sigactionFrom(signal: signal)).handler == .defaultHandler
	}
	
	private struct UnsigactionedSignal {
		
		static let signalProcessingQueue = DispatchQueue(label: "com.xcode-actions.unsigactioned-signal-processing")
//		static let threadForSignalResend = pthread_create(<#T##UnsafeMutablePointer<pthread_t?>!#>, <#T##UnsafePointer<pthread_attr_t>?#>, <#T##(UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?#>, <#T##UnsafeMutableRawPointer?#>)
		
		var originalSigaction: Sigaction
		
		var dispatchSource: DispatchSourceSignal
		var unsigactionInfo = [UnsigactionID: OriginalHandlerAction]()
		
	}
	
	private static var unsigactionedSignals = [Signal: UnsigactionedSignal]()
	
	@inline(__always)
	private static func sigactionFrom(signal: Signal) throws -> sigaction {
		var action = sigaction()
		guard sigaction(signal.rawValue, nil, &action) == 0 else {
			throw SignalHandlingError.systemError(Errno(rawValue: errno))
		}
		return action
	}
	
	/**
	Installs the given sigaction and returns the old one if different. Returns
	the old sigaction if different than the new one. */
	@discardableResult
	private static func installSigaction(signal: Signal, action newSigaction: Sigaction) throws -> Sigaction? {
		var oldCAction = sigaction()
		var newCAction = newSigaction.rawValue
		guard sigaction(signal.rawValue, &newCAction, &oldCAction) == 0 else {
			throw SignalHandlingError.systemError(Errno(rawValue: errno))
		}
		let oldSigaction = Sigaction(rawValue: oldCAction)
		if oldSigaction != newSigaction {return oldSigaction}
		else                            {return nil}
	}
	
	/** Must always be called on the `UnsigactionedSignal.signalProcessingQueue`. */
	private static func processSignalFromDispatch(signal: Signal, count: UInt) {
		SignalHandlingConfig.logger?.debug("Processing signals, called from libdispatch", metadata: ["signal": "\(signal)", "count": "\(count)"])
		#warning("TODO: Use the OriginalHandlerActions")
		/* Caught by libdispatch */
//		raise(signal.rawValue)
		do {
			SignalHandlingConfig.logger?.debug("\(pthread_self())")
			#warning("TODO: No forced unwrap")
			let back = try installSigaction(signal: signal, action: unsigactionedSignals[signal]!.originalSigaction)
			/* Not caught by libdispatch because it uses kqueue which specifically
			 * does not send signals sent to thread.
			 * TODO: Test this on Linux. If it does not work, I have no idea what
			 *       to do in replacement though… */
			/* TODO: Send signal to a thread we create ourself otherwise we get
			 *       error 45 (let’s hope it’ll work w/ thread we create).*/
			let ret = pthread_kill(pthread_self(), 0)
			if ret != 0 {
				SignalHandlingConfig.logger?.debug("\(ENOTSUP)")
				SignalHandlingConfig.logger?.error("Cannot send signal to thread: error \(Errno(rawValue: ret)).", metadata: ["signal": "\(signal)"])
			}
			if let back = back {try installSigaction(signal: signal, action: back)}
		} catch {
			SignalHandlingConfig.logger?.error("Error installing a sigaction when sending original signal back. Signal might have been dropped, or not set back to ignore.", metadata: ["signal": "\(signal)"])
		}
	}
	
	private init() {}
	
}


private extension OpaquePointer {
	
	init?(sigHandler: sig_t?) {
		self.init(bitPattern: unsafeBitCast(sigHandler, to: Int.self))
	}
	
}
