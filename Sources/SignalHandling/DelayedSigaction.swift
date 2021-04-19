import Foundation

import SystemPackage



public struct DelayedSigaction : Hashable {
	
	/**
	Handler called when a delayed sigaction signal is received. Handler shall
	call the passed handler when sigaction is ready to be called, or dropped.
	
	- Note: The sigaction might not be called as soon as the handler is called,
	or not at all. Multiple clients can delay the sigaction, and all clients must
	allow it to be sent for the sigaction to be sent.
	
	- Parameter signal: The signal that triggered the delayed sigaction.
	- Parameter sigactionAllowedHandler: The handler to call when the sigaction
	can be triggered or dropped.
	- Parameter allowSigaction: Whether the sigaction handler should be called,
	or the signal should be dropped. */
	public typealias DelayedSigactionHandler = (_ signal: Signal, _ sigactionAllowedHandler: (_ allowSigaction: Bool) -> Void) -> Void
	
	/**
	Prepare the process for delayed sigaction by blocking all signals on the main
	thread and spawning a thread to handle signals.
	
	Delayed sigaction is done by blocking delayed signals until the time has come
	to call the sigaction handler.
	If any thread does not block the delayed signal, the sigaction will be called
	before its time!
	
	- Note: How do we know a signal has arrived if it is blocked? We use
	libdispatch to be notified when a new signal arrives. libdispatch uses kqueue
	on BSD and signalfd on Linux. Signals are still sent to kqueue and signalfd
	when they are blocked, so it works.
	
	- Important: Must be called before any thread is spawned.
	- Important: You should not use pthread_sigmask to sigprocmask (nor anything
	to unblock signals) after calling this method. */
	public static func bootstrap() throws {
		guard !bootstrapDone else {
			fatalError("DelayedSigaction can be bootstrapped only once")
		}
		
		var allSignals = Signal.fullSigset
		let ret = pthread_sigmask(SIG_SETMASK, &allSignals, nil /* old signals */)
		if ret != 0 {
			throw SignalHandlingError.nonDestructiveSystemError(Errno(rawValue: ret))
		}
		
		var error: Error?
		let group = DispatchGroup()
		group.enter()
		Thread.detachNewThread{
			Thread.current.name = "com.xcode-actions.signal-handler-thread"
			
			/* Unblock all signals in this thread. */
			var noSignals = Signal.emptySigset
			let ret = pthread_sigmask(SIG_SETMASK, &noSignals, nil /* old signals */)
			if ret != 0 {
				error = SignalHandlingError.destructiveSystemError(Errno(rawValue: ret))
			}
			group.leave()
			
			if ret == 0 {
				delayedSigactionThreadLoop()
			}
		}
		group.wait()
		if let e = error {throw e}
	}
	
	public static func registerDelayedSigaction(_ signal: Signal, handler: @escaping DelayedSigactionHandler) throws -> DelayedSigaction {
		return try signalProcessingQueue.sync{
			try registerDelayedSigaction(signal, handler: handler)
		}
	}
	
	public static func unregisterDelayedSigaction(_ delayedSigaction: DelayedSigaction) throws {
		return try signalProcessingQueue.sync{
			try unregisterDelayedSigactionOnQueue(delayedSigaction)
		}
	}
	
	/**
	Convenience to register a delayed sigaction on multiple signals with the same
	handler in one function call.
	
	If a delay cannot be registered on one of the signal, the other signals that
	were successfully registered will be unregistered. Of course this can fail
	too, in which case an error will be logged (but nothing more will be done). */
	public static func registerDelayedSigactions(_ signals: Set<Signal>, handler: @escaping DelayedSigactionHandler) throws -> [Signal: DelayedSigaction] {
		return try signalProcessingQueue.sync{
			var ret = [Signal: DelayedSigaction]()
			for signal in signals {
				do {
					ret[signal] = try registerDelayedSigactionOnQueue(signal, handler: handler)
				} catch {
					for (signal, UnsigactionID) in ret {
						do    {try unregisterDelayedSigactionOnQueue(UnsigactionID)}
						catch {SignalHandlingConfig.logger?.error("Cannot unregister delayed sigaction for in recovery handler of registerDelayedSigactions. The signal will stay blocked, probably forever.", metadata: ["signal": "\(signal)"])}
					}
					throw error
				}
			}
			return ret
		}
	}
	
	public func unregister() throws {
		try DelayedSigaction.unregisterDelayedSigaction(self)
	}
	
	/* ***************
	   MARK: - Private
	   *************** */
	
	private struct DelayedSignal {
		
		var dispatchSource: DispatchSourceSignal
		var handlers = [DelayedSigaction: DelayedSigactionHandler]()
		
	}
	
	private enum DelayedSignalSync : Int {
		
		enum Action {
			case nop
			case drop(Signal)
			case block(Signal)
			case unblock(Signal)
			case suspend(for: Signal)
			case endThread /* Not actually used, but implemented. Would be useful in an unboostrap method. */
			
			var isNop: Bool {
				if case .nop = self {return true}
				return false
			}
		}
		
		static let lock = NSConditionLock(condition: Self.nothingToDo.rawValue)
		
		static var action: Action = .nop
		static var error: Error?
		
		case nothingToDo
		case actionInThread
		case waitActionCompletion
		
	}
	
	private static var nextID = 0
	private static var bootstrapDone = false
	
	private static var delayedSignals = [Signal: DelayedSignal]()
	
	private static let signalProcessingQueue = DispatchQueue(label: "com.xcode-actions.signal-processing-queue")
	
	private static func executeOnThread(_ action: DelayedSignalSync.Action) throws {
		do {
			DelayedSignalSync.lock.lock(whenCondition: DelayedSignalSync.nothingToDo.rawValue)
			defer {DelayedSignalSync.lock.unlock(withCondition: DelayedSignalSync.actionInThread.rawValue)}
			assert(DelayedSignalSync.error == nil, "non-nil error but acquired lock in nothingToDo state.")
			assert(DelayedSignalSync.action.isNop, "non-nop action but acquired lock in nothingToDo state.")
			DelayedSignalSync.action = action
		}
		
		do {
			DelayedSignalSync.lock.lock(whenCondition: DelayedSignalSync.waitActionCompletion.rawValue)
			defer {
				DelayedSignalSync.error = nil
				DelayedSignalSync.lock.unlock(withCondition: DelayedSignalSync.nothingToDo.rawValue)
			}
			assert(DelayedSignalSync.action.isNop, "non-nop action but acquired lock in waitActionCompletion state.")
			if let e = DelayedSignalSync.error {
				throw e
			}
		}
	}
	
	private static func registerDelayedSigactionOnQueue(_ signal: Signal, handler: @escaping DelayedSigactionHandler) throws -> DelayedSigaction {
		let delayedSigaction = DelayedSigaction(signal: signal)
		
		var delayedSignal: DelayedSignal
		if let ds = delayedSignals[signal] {
			delayedSignal = ds
		} else {
			try executeOnThread(.block(signal))
			
			let dispatchSourceSignal = DispatchSource.makeSignalSource(signal: signal.rawValue, queue: signalProcessingQueue)
			dispatchSourceSignal.setEventHandler{ [weak dispatchSourceSignal] in
				guard let dispatchSourceSignal = dispatchSourceSignal else {
					SignalHandlingConfig.logger?.error("INTERNAL ERROR: Event handler called, but dispatch source is nil", metadata: ["signal": "\(signal)"])
					return
				}
				processSignalsOnQueue(signal: signal, count: dispatchSourceSignal.data)
			}
			dispatchSourceSignal.activate()
			
			delayedSignal = DelayedSignal(dispatchSource: dispatchSourceSignal)
		}
		
		assert(delayedSignal.handlers[delayedSigaction] == nil)
		delayedSignal.handlers[delayedSigaction] = handler
		delayedSignals[signal] = delayedSignal
		
		return delayedSigaction
	}
	
	private static func unregisterDelayedSigactionOnQueue(_ delayedSigaction: DelayedSigaction) throws {
		let signal = delayedSigaction.signal
		
		guard var delayedSignal = delayedSignals[signal] else {
			/* We trust our source not to have an internal logic error. If the
			 * delayed sigaction is not found, it is because the callee called
			 * unregister twice on the same delayed sigaction. */
			SignalHandlingConfig.logger?.error("Delayed sigaction unregistered more than once", metadata: ["signal": "\(signal)"])
			return
		}
		assert(!delayedSignal.handlers.isEmpty, "INTERNAL ERROR: handlers should never be empty because when it is, the whole delayed signal should be removed.")
		
		guard delayedSignal.handlers.removeValue(forKey: delayedSigaction) != nil else {
			/* Same here. If the delayed sigaction was not in the handlers, it can
			 * only be because the callee called unregister twice with the object. */
			SignalHandlingConfig.logger?.error("Delayed sigaction unregistered more than once", metadata: ["signal": "\(signal)"])
			return
		}
		
		if !delayedSignal.handlers.isEmpty {
			/* We have nothing more to do except update the delayed signals: there
			 * are more delayed signals that have been registered for this signal,
			 * so we cannot unblock the signal. */
			delayedSignals[signal] = delayedSignal
			return
		}
		
		/* Now we have removed **all** delayed sigactions on the given signal.
		 * Let’s unblock the signal! */
		try executeOnThread(.unblock(signal))
		delayedSignal.dispatchSource.cancel()
		
		/* Finally, once the sigaction has been restored to the original value, we
		 * can remove the unsigactioned signal from the list. */
		delayedSignals.removeValue(forKey: signal)
	}
	
	/** Must always be called on the `signalProcessingQueue`. */
	private static func processSignalsOnQueue(signal: Signal, count: UInt) {
		SignalHandlingConfig.logger?.debug("Processing signals, called from libdispatch", metadata: ["signal": "\(signal)", "count": "\(count)"])
		
		/* Get the delayed signal for the given signal. */
		guard let delayedSignal = delayedSignals[signal] else {
			SignalHandlingConfig.logger?.error("INTERNAL ERROR: nil delayed signal.", metadata: ["signal": "\(signal)"])
			return
		}
		
		for _ in 0..<count {
			let group = DispatchGroup()
			var runOriginalHandlerFinal = true
			for (_, handler) in delayedSignal.handlers {
				group.enter()
				handler(signal, { runOriginalHandler in
					runOriginalHandlerFinal = runOriginalHandlerFinal && runOriginalHandler
					group.leave()
				})
			}
			group.wait()
			
			/* All the handlers have responded, we now know whether to allow or
			 * drop the signal. */
			do {try executeOnThread(runOriginalHandlerFinal ? .suspend(for: signal) : .drop(signal))}
			catch {
				SignalHandlingConfig.logger?.error("Error while \(runOriginalHandlerFinal ? "suspending thread" : "dropping signal in thread").", metadata: ["signal": "\(signal)"])
			}
		}
	}
	
	private static func delayedSigactionThreadLoop() {
		runLoop: repeat {
			loggerLessThreadSafeDebugLog("🧵 New delayed sigaction thread loop")
			
			DelayedSignalSync.lock.lock(whenCondition: DelayedSignalSync.actionInThread.rawValue)
			defer {
				DelayedSignalSync.action = .nop
				DelayedSignalSync.lock.unlock(withCondition: DelayedSignalSync.waitActionCompletion.rawValue)
			}
			
			assert(DelayedSignalSync.error == nil, "non-nil error but acquired lock in actionInThread state.")
			
			do {
				switch DelayedSignalSync.action {
					case .nop:
						(/*nop*/)
						assertionFailure("nop action while being locked w/ action in thread")
						
					case .endThread:
						loggerLessThreadSafeDebugLog("🧵 Processing endThread action")
						break runLoop
						
					case .block(let signal):
						loggerLessThreadSafeDebugLog("🧵 Processing block action for \(signal)")
						var sigset = signal.sigset
						let ret = pthread_sigmask(SIG_BLOCK, &sigset, nil /* old signals */)
						if ret != 0 {
							throw SignalHandlingError.destructiveSystemError(Errno(rawValue: ret))
						}
						
					case .unblock(let signal):
						loggerLessThreadSafeDebugLog("🧵 Processing unblock action for \(signal)")
						var sigset = signal.sigset
						let ret = pthread_sigmask(SIG_UNBLOCK, &sigset, nil /* old signals */)
						if ret != 0 {
							throw SignalHandlingError.destructiveSystemError(Errno(rawValue: ret))
						}
						
					case .suspend(for: let signal):
						loggerLessThreadSafeDebugLog("🧵 Processing suspend action for \(signal)")
						var sigset = sigset_t()
						let ret = pthread_sigmask(SIG_SETMASK, nil /* new signals */, &sigset)
						if ret != 0 {
							throw SignalHandlingError.nonDestructiveSystemError(Errno(rawValue: ret))
						}
						sigdelset(&sigset, signal.rawValue)
						/* WHYYYYYYY??? */
						pthread_kill(pthread_self(), signal.rawValue)
						sigsuspend(&sigset)
						
					case .drop(let signal):
						loggerLessThreadSafeDebugLog("🧵 Processing drop action for \(signal)")
						var sigset = sigset_t()
						let ret = pthread_sigmask(SIG_SETMASK, nil /* new signals */, &sigset)
						if ret != 0 {
							throw SignalHandlingError.nonDestructiveSystemError(Errno(rawValue: ret))
						}
						sigdelset(&sigset, signal.rawValue)
						
						let oldAction = try Sigaction.ignoreAction.install(on: signal, revertIfIgnored: false)
						/* WHYYYYYYY??? */
						pthread_kill(pthread_self(), signal.rawValue)
						sigsuspend(&sigset)
						if let oldAction = oldAction {
							do {try oldAction.install(on: signal, revertIfIgnored: false)}
							catch let error as SignalHandlingError {
								throw error.upgradeToDestructive()
							}
						}
				}
			} catch {
				DelayedSignalSync.error = error
			}
		} while true
	}
	
	/**
	Best effort log to stderr using write (no retry on signal). For debug only.
	Marked as deprecated to force a warning if used. */
	@available(*, deprecated, message: "This method should never be called in production.")
	private static func loggerLessThreadSafeDebugLog(_ str: String) {
		(str + "\n").utf8CString.withUnsafeBytes{ buffer in
			guard buffer.count > 0 else {return}
			_ = write(2, buffer.baseAddress! /* buffer size > 0, so !-safe */, buffer.count)
		}
	}
	
	private var id: Int
	private var signal: Signal
	
	private init(signal: Signal) {
		defer {Self.nextID += 1}
		self.id = Self.nextID
		self.signal = signal
	}
	
	public static func ==(_ lhs: DelayedSigaction, _ rhs: DelayedSigaction) -> Bool {
		return lhs.id == rhs.id
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
	
}
