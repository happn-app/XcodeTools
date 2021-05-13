import Foundation

import Logging



public struct XcodeToolsConfig {
	
	public static var logger: Logging.Logger? = {
		return Logger(label: "com.xcode-actions.XcodeTools")
	}()
	
	/** This struct is simply a container for static configuration properties. */
	private init() {}
	
}
