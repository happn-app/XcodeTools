import Foundation

import Logging



public struct XcodeJsonOutputConfig {
	
	public static var logger: Logging.Logger? = {
		return Logger(label: "com.xcode-actions.XcodeJsonOutput")
	}()
	
	/** This struct is simply a container for static configuration properties. */
	private init() {}
	
}

typealias Conf = XcodeJsonOutputConfig
