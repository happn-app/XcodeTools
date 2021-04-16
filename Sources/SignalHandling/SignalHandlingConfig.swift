import Foundation

import Logging



public struct SignalHandlingConfig {
	
	public static var logger: Logging.Logger? = {
		return Logger(label: "com.xcode-actions.signal-handling")
	}()
	
	/** This struct is simply a container for static configuration properties. */
	private init() {}
	
}
