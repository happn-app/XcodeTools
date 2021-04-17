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
	Installs the given sigaction and returns the old one if different. Returns
	the old sigaction if different than the new one.
	
	It is a programer error to install a sigaction after unsigactioning a signal,
	before the signal has been fully unsigactioned. Behaviour will be undefined
	if you do it. */
	@discardableResult
	public static func installSigaction(signal: Signal, action newSigaction: Sigaction) throws -> Sigaction? {
		var oldCAction = sigaction()
		var newCAction = newSigaction.rawValue
		guard sigaction(signal.rawValue, &newCAction, &oldCAction) == 0 else {
			throw SignalHandlingError.systemError(Errno(rawValue: errno))
		}
		let oldSigaction = Sigaction(rawValue: oldCAction)
		if oldSigaction != newSigaction {return oldSigaction}
		else                            {return nil}
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
		static var threadForSignalResend: pthread_t? = {
			var threadAttr = pthread_attr_t()
			pthread_attr_init(&threadAttr)
			pthread_attr_setdetachstate(&threadAttr, PTHREAD_CREATE_DETACHED)
			pthread_attr_set_qos_class_np(&threadAttr, QOS_CLASS_BACKGROUND, QOS_MIN_RELATIVE_PRIORITY)
			
			var mutexAttr = pthread_mutexattr_t()
			
			let mutexAttrInitSuccess = (pthread_mutexattr_init(&mutexAttr) == 0)
			defer {
				if mutexAttrInitSuccess {
					if pthread_mutexattr_destroy(&mutexAttr) != 0 {
						SignalHandlingConfig.logger?.error("Cannot destroy mutex attr for thread for signal resend. Leaking.")
					}
				}
			}
			if !mutexAttrInitSuccess {
				SignalHandlingConfig.logger?.error("Cannot init mutex attr for thread for signal resend. We will init mutex with default attrs.")
			}
			
			/* Setting mutex attributes if attributes init succeeded. */
			if mutexAttrInitSuccess {
				if pthread_mutexattr_settype(&mutexAttr, PTHREAD_MUTEX_NORMAL) != 0 {
					SignalHandlingConfig.logger?.error("Cannot mutex attr type to NORMAL for thread for signal resend. Leaving to default.")
				}
			}
			
			var mutex = pthread_mutex_t()
			let mutexInitResult = mutexAttrInitSuccess
				? pthread_mutex_init(&mutex, &mutexAttr)
				: pthread_mutex_init(&mutex, nil)
			let mutexInitSuccess = (mutexInitResult == 0)
			defer {
				if mutexInitSuccess {
					if pthread_mutex_destroy(&mutex) != 0 {
						SignalHandlingConfig.logger?.error("Cannot destroy mutex. Leaking.")
					}
				}
			}
			if !mutexInitSuccess {
				SignalHandlingConfig.logger?.error("Cannot init mutex for thread for signal resend. Not waiting on condition; first signal might not be resent.")
			}
			
			waitOnConditionInThreadForSignalResendInit = mutexInitSuccess
			
			/* Create and start the thread */
			var thread: pthread_t?
			guard pthread_create(&thread, &threadAttr, threadForSignalResendMain, nil) == 0, thread != nil else {
				SignalHandlingConfig.logger?.error("Cannot create thread for signal resend; resending signals will probably fail.")
				return nil
			}
			
			/* Let’s wait for the thread to be started. If we don’t, we might get a
			 * race when signal is resent to this thread and signal might not be
			 * processed. */
			if waitOnConditionInThreadForSignalResendInit {
				pthread_mutex_lock(&mutex);
				if pthread_cond_wait(&conditionForThreadForSignalResendInit, &mutex) != 0 {
					SignalHandlingConfig.logger?.error("Cannot wait on condition for thread for signal resend. We may get a block thread and a stuck program.")
				}
				pthread_mutex_unlock(&mutex);
				SignalHandlingConfig.logger?.trace("Condition for thread for signal resend done.")
			}
			
			return thread
		}()
		
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
	
	/** Must always be called on the `UnsigactionedSignal.signalProcessingQueue`. */
	private static func processSignalFromDispatch(signal: Signal, count: UInt) {
		SignalHandlingConfig.logger?.debug("Processing signals, called from libdispatch", metadata: ["signal": "\(signal)", "count": "\(count)"])
		#warning("TODO: Use the OriginalHandlerActions")
		do {
			guard let original = unsigactionedSignals[signal]?.originalSigaction else {
				SignalHandlingConfig.logger?.error("INTERNAL ERROR: nil original sigaction.", metadata: ["signal": "\(signal)"])
				return
			}
			SignalHandlingConfig.logger?.debug("Original sigaction: \(original)")
			let back = try installSigaction(signal: signal, action: original)
			/* Not caught by libdispatch because it uses kqueue which specifically
			 * does not catch signals sent to threads.
			 * Signals being process-wide (even those sent to threads), the
			 * sigaction handler will still be executed.
			 * TODO: Test this. If it does not work, I have no idea what to do in
			 *       replacement though… */
			let thread = UnsigactionedSignal.threadForSignalResend ?? pthread_self()
			SignalHandlingConfig.logger?.debug("Sending kill signal to thread \(thread)")
			/* Both work for raising the signal w/o being caught by libdispatch.
			 * pthread_kill might be safer, because it should really not be caught
			 * by libdispatch, while raise might (it should not either, but it is
			 * less clear; IIUC in a multithreaded env it should never be caught
			 * though).
			 * Anyway, we need to reinstall the sigaction handler after the signal
			 * has been sent and processed, so we need to have some control, which
			 * raise do not give. */
//			let ret = raise(signal.rawValue)
			let ret = pthread_kill(thread, signal.rawValue)
			if ret != 0 {
				SignalHandlingConfig.logger?.error("Cannot send signal to thread: error \(Errno(rawValue: ret)).", metadata: ["signal": "\(signal)"])
			}
			/* Reinstalling the sigaction handler directly here does not work (the
			 * signal will not be ignored before it will have time to be sent on
			 * its thread by pthread_kill. We have to wait for pause to return.
			 * We will want to wait here and use a pthread condition probably. We
			 * could use a mutex and a global var to “send” the original sigaction
			 * to the thread, and set the sigaction directly in the thread, but I
			 * think it’s best this handling block do not finish until the resend
			 * is done. */
//			UnsigactionedSignal.signalProcessingQueue.asyncAfter(deadline: .now() + .milliseconds(500)){
//				if let back = back {try! installSigaction(signal: signal, action: back)}
//			}
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



private var waitOnConditionInThreadForSignalResendInit = false

private var conditionForThreadForSignalResendInit: pthread_cond_t = {
	var cond = pthread_cond_t()
	guard pthread_cond_init(&cond, nil) == 0 else {
		SignalHandlingConfig.logger?.error("Cannot init condition for thread for signal resend. We may get a block thread and a stuck program.")
		#warning("TODO: Return nil")
		return cond
	}
	return cond
}()

/* Must be out of SignalHandling struct because called by C */
private func threadForSignalResendMain(_ arg: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
	var mask = Signal.sigset(from: [])
	pthread_sigmask(SIG_SETMASK, &mask, nil)
	if waitOnConditionInThreadForSignalResendInit && pthread_cond_signal(&conditionForThreadForSignalResendInit) != 0 {
		SignalHandlingConfig.logger?.error("Cannot signal init condition for thread for signal resend. We may get a block thread and a stuck program.")
	}
	repeat {
		SignalHandlingConfig.logger?.trace("Pausing thread for signal resend")
		/* pause has been made obsolete by sigsuspend, but in our case I think we
		 * do want pause and not sigsuspend. sigsuspend unblocks the signal it is
		 * given, which is not what we want. We just want to wait until any signal
		 * is received. */
		pause()
		SignalHandlingConfig.logger?.trace("Pause returned")
	} while true
}
