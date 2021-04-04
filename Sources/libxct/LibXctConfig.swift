import Foundation

import Logging



public struct LibXctConfig {
	
	public static var logger: Logging.Logger? = {
		return Logger(label: "com.xcode-actions.libxct")
	}()
	
	/** This struct is simply a container for static configuration properties. */
	private init() {}
	
}
