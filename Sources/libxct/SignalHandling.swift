import Foundation

import SystemPackage



public struct SignalHandling {
	
	public enum SignalHandler {
		
		/**
		The simple signal handler. Same as the extended, but you don’t get the
		additional arguments.
		
		In theory there is no need to use this handler style as
		1/ The `SignalHandling` struct will _always_ register a handler using the
		`SA_SIGINFO` bit in the flags, and
		2/ The system always send the additional arguments anyway (says the man on
		macOS 11). */
		case standard((_ signal: Signal) -> Void)
		case extended((_ signal: Signal, UnsafeMutablePointer<__siginfo>?, UnsafeMutableRawPointer?) -> Void)
		
	}
	
	public struct InstalledSignalHandlerID : Hashable {
		
		private static var latestID = 0
		
		internal var id: Int
		
		internal var signal: Signal
		internal var handler: SignalHandler
		
		internal init(signal: Signal, handler: SignalHandler) {
			defer {Self.latestID += 1}
			
			self.id = Self.latestID
			self.signal = signal
			self.handler = handler
		}
		
		public static func ==(_ lhs: InstalledSignalHandlerID, _ rhs: InstalledSignalHandlerID) -> Bool {
			return lhs.id == rhs.id
		}
		
		public func hash(into hasher: inout Hasher) {
			hasher.combine(id)
		}
		
	}
	
	/**
	Installs a handler for the given signal. The original handler for the given
	signal will still be called (after the one you register).
	However, if the signal handler is modified by other means than this function,
	we cannot detect it in real time. We can detect it later though (probably;
	TODO), but it is not very useful. Attempting to install a handler when the
	signal handler has been detected to be modified outside of this method will
	throw an error.
	
	Usually, `bypassIgnored` should be set to `false` (the default). If the
	signal has been ignored, it was probably for a good reason (often set by the
	parent process). */
	public static func installSignalHandler(bypassIgnored: Bool = false, signal: Signal, handler: SignalHandler) throws -> InstalledSignalHandlerID? {
		var oldAction = sigaction()
		guard sigaction(signal.rawValue, nil, &oldAction) == 0 else {
			throw LibXctError.systemError(Errno(rawValue: errno))
		}
		
		if let currentHandler = registrationsInfo[signal] {
			assert(registrationsInfo[signal]!.handlerIDs.count >= 1)
			/* Let’s check the handler has not been changed. */
			guard areSigactionHandlersEqual(currentHandler.ourSigaction.__sigaction_u.__sa_handler, oldAction.__sigaction_u.__sa_handler) else {
				throw LibXctError.signalHandlerChangedOutOfLib
			}
		} else {
			/* No handlers were installed (by us) for this */
			
			/* Why going through the OpaquePointer hoop and not use directly the
			 * unsafe bitcast to Int?
			 * That way, if a pointer is not of size `MemoryLayout<Int>.size`, the
			 * following line should not compile anymore. Without the OpaquePointer
			 * they probably still would, but would probably not be valid anymore. */
			let sigIgnOpaque = OpaquePointer(bitPattern: unsafeBitCast(SIG_IGN, to: Int.self))
			let sigDflOpaque = OpaquePointer(bitPattern: unsafeBitCast(SIG_DFL, to: Int.self))
			let oldActionHandlerOpaque = OpaquePointer(bitPattern: unsafeBitCast(oldAction.__sigaction_u.__sa_handler, to: Int.self))
			let oldActionIsDefault = (oldActionHandlerOpaque != sigDflOpaque)
			let oldActionIsIgnore = (oldActionHandlerOpaque != sigIgnOpaque)
			/* There are no other possibilites AFAIK (and AFA the man tells) */
			let oldActionIsCustom = !oldActionIsIgnore && !oldActionIsDefault
			
			guard bypassIgnored || !oldActionIsIgnore else {
				return nil
			}
			
			var newAction = sigaction()
			if oldActionIsCustom {
				/* If there already was a handler, we keep the same flags and mask,
				 * except we remove the SA_NODEFER flag that we do need.
				 * Is it the proper thing to do? I don’t know. But it’s what we do
				 * for now. */
				newAction.sa_mask = oldAction.sa_mask
				newAction.sa_flags = oldAction.sa_flags & ~SA_NODEFER
			} else {
				/* We only block the signal being delivered during the execution of
				 * the handler (default behaviour) */
				newAction.sa_mask = 0
				/* No flags seem interesting to me at the moment (SA_SIGINFO is set
				 * later). See sigaction(2) for more info.
				 * GNU version of the man here: https://man7.org/linux/man-pages/man2/sigaction.2.html */
				newAction.sa_flags = 0
			}
			newAction.sa_flags = (newAction.sa_flags | SA_SIGINFO)
			newAction.__sigaction_u.__sa_sigaction = handleSignal
			guard sigaction(signal.rawValue, &newAction, nil) == 0 else {
				throw LibXctError.systemError(Errno(rawValue: errno))
			}
			
			let handlerID = InstalledSignalHandlerID(signal: signal, handler: .extended({ signal, siginfo, userThreadContext in
				#warning("TODO: Call original handler (in oldAction)")
				print("Must call original handler")
			}))
			registrationsInfo[signal] = RegistrationInfo(originalSigaction: oldAction, ourSigaction: newAction, handlerIDs: [handlerID])
		}
		
		registrationsInfo[signal]!.handlerIDs.append(InstalledSignalHandlerID(signal: signal, handler: handler))
		return InstalledSignalHandlerID(signal: signal, handler: handler)
	}
	
	public static func removeSignalHandler(_ handler: InstalledSignalHandlerID) throws -> Bool {
		guard var info = registrationsInfo[handler.signal], let idx = info.handlerIDs.firstIndex(of: handler) else {
			return false
		}
		
		info.handlerIDs.remove(at: idx)
		assert(info.handlerIDs.count >= 1)
		if info.handlerIDs.count == 1 {
			registrationsInfo.removeValue(forKey: handler.signal)
			guard sigaction(handler.signal.rawValue, &info.originalSigaction, nil) == 0 else {
				throw LibXctError.systemError(Errno(rawValue: errno))
			}
		} else {
			registrationsInfo[handler.signal] = info
		}
		
		assert(registrationsInfo[handler.signal]?.handlerIDs.firstIndex(of: handler) == nil)
		return true
	}
	
	fileprivate struct RegistrationInfo {
		
		var originalSigaction: sigaction
		var ourSigaction: sigaction
		
		var handlerIDs: [InstalledSignalHandlerID]
		
	}
	
	fileprivate static var registrationsInfo = [Signal: RegistrationInfo]()
	
	private static func areSigactionHandlersEqual(_ lhs: @escaping sig_t, _ rhs: @escaping sig_t) -> Bool {
		/* Why going through the OpaquePointer hoop and not use directly the
		 * unsafe bitcast to Int?
		 * That way, if a pointer is not of size `MemoryLayout<Int>.size`, the
		 * following line should not compile anymore. Without the OpaquePointer
		 * they probably still would, but would probably not be valid anymore. */
		let lhsOpaque = OpaquePointer(bitPattern: unsafeBitCast(lhs, to: Int.self))
		let rhsOpaque = OpaquePointer(bitPattern: unsafeBitCast(rhs, to: Int.self))
		return lhsOpaque == rhsOpaque
	}
	
	private init() {}
	
}

/* Must be outside the SignalHandling struct because referenced by C. */
private func handleSignal(_ signalID: CInt, _ siginfo: UnsafeMutablePointer<__siginfo>?, _ userThreadContext: UnsafeMutableRawPointer?) {
	let signal = Signal(rawValue: signalID)
	
	/* Do **NOT** log anything using a logger! A logger will most definitely use
	 * a method which would be considered unsafe to be used in a signal handler… */
//	print("Got signal: \(signal.signalDescription ?? "Unknown signal!")")
	
	guard let signalHandlers = SignalHandling.registrationsInfo[signal]?.handlerIDs, signalHandlers.count >= 1 else {
		LibXctConfig.logger?.error("Got nil or count < 1 signal handlers list for signal \(signal); this should not be possible! (If all handlers are removed, so should the sigaction handler.)")
		return
	}
	/* We call the handlers in reverse because we want the latest one to be added
	 * to be called last. The first handler to be added will always the be one
	 * calling the original handler (before we installed our sigaction handler). */
	for handlerID in signalHandlers.reversed() {
		switch handlerID.handler {
			case .standard(let handler): handler(signal)
			case .extended(let handler): handler(signal, siginfo, userThreadContext)
		}
	}
}
