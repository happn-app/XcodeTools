import Foundation



public struct Sigaction : Equatable, RawRepresentable {
	
	public static let ignoreAction = Sigaction(handler: .ignoreHandler)
	public static let defaultAction = Sigaction(handler: .defaultHandler)
	
	public var mask: Set<Signal> = []
	public var flags: SigactionFlags = []
	
	public var handler: SigactionHandler
	
	public init(handler: SigactionHandler) {
		self.mask = []
		switch handler {
			case .posix:                                  self.flags = [.siginfo]
			case .ignoreHandler, .defaultHandler, .ansiC: self.flags = []
		}
		self.handler = handler
	}
	
	/**
	Create a `Sigaction` from a `sigaction`.
	
	If the handler of the sigaction is `SIG_IGN` or `SIG_DFL`, we check the
	`sa_flags` not to contains the `SA_SIGINFO` bit. If they do, we log an error,
	as this is invalid. */
	public init(rawValue: sigaction) {
		self.mask = Signal.set(from: rawValue.sa_mask)
		self.flags = SigactionFlags(rawValue: rawValue.sa_flags)
		
		switch OpaquePointer(bitPattern: unsafeBitCast(rawValue.__sigaction_u.__sa_handler, to: Int.self)) {
			case OpaquePointer(bitPattern: unsafeBitCast(SIG_IGN, to: Int.self)): self.handler = .ignoreHandler
			case OpaquePointer(bitPattern: unsafeBitCast(SIG_DFL, to: Int.self)): self.handler = .defaultHandler
			default:
				if flags.contains(.siginfo) {self.handler = .posix(rawValue.__sigaction_u.__sa_sigaction)}
				else                        {self.handler = .ansiC(rawValue.__sigaction_u.__sa_handler)}
		}
		
		if !isValid {
			SignalHandlingConfig.logger?.warning("Initialized an invalid Sigaction.")
		}
	}
	
	public var rawValue: sigaction {
		if !isValid {
			SignalHandlingConfig.logger?.warning("Getting sigaction from an invalid Sigaction.")
		}
		
		var ret = sigaction()
		ret.sa_mask = Signal.sigset(from: mask)
		ret.sa_flags = flags.rawValue
		
		switch handler {
			case .ignoreHandler:  ret.__sigaction_u.__sa_handler = SIG_IGN
			case .defaultHandler: ret.__sigaction_u.__sa_handler = SIG_DFL
			case .ansiC(let h):   ret.__sigaction_u.__sa_handler = h
			case .posix(let h):   ret.__sigaction_u.__sa_sigaction = h
		}
		
		return ret
	}
	
	/**
	Only one check: do the flags **not** contain `siginfo` if handler is either
	`.ignoreHandler` or `.defaultHandler`. */
	public var isValid: Bool {
		return !flags.contains(.siginfo) || (handler != .ignoreHandler && handler != .defaultHandler)
	}
	
}
