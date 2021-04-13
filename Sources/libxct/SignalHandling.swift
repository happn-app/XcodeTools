import Foundation



public struct SignalHandling {
	
	public typealias SignalHandler = () -> Void
	
	public struct InstalledSignalHandlerID : Hashable {
		
		private static var latestID = 0
		
		internal var id: Int
		
		internal var signal: Signal
		internal var handler: SignalHandler
		
		internal init(signal: Signal, handler: @escaping SignalHandler) {
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
	
	public static func installSignalHandler(bypassIgnored: Bool = false, signal: Signal, handler: @escaping SignalHandler) throws -> InstalledSignalHandlerID {
//		let newAction = sigaction()
//		newAction.__sigaction_u
//		sigaction(<#T##Int32#>, <#T##UnsafePointer<sigaction>!#>, <#T##UnsafeMutablePointer<sigaction>!#>)
//		NSIG
//		signal(<#T##Int32#>, <#T##((Int32) -> Void)!##((Int32) -> Void)!##(Int32) -> Void#>)
		return InstalledSignalHandlerID(signal: signal, handler: handler)
	}
	
	public static func removeSignalHandler(_ handler: InstalledSignalHandlerID) -> Bool {
		guard let idx = handlers[handler.signal]?.firstIndex(of: handler) else {
			return false
		}
		
		handlers[handler.signal]?.remove(at: idx)
		if handlers[handler.signal]?.isEmpty ?? false {
			handlers.removeValue(forKey: handler.signal)
		}
		
		assert(handlers[handler.signal]?.firstIndex(of: handler) == nil)
		return true
	}
	
	private static var handlers = [Signal: [InstalledSignalHandlerID]]()
	
	private init() {}
	
}
