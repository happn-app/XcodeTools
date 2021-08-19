import Foundation

import Logging



/** A container to hold the properties that can modify the behaviour of the
 module. */
public enum XcodeToolsConfig {
	
	/* TODO: Migrate to TaskLocal */
	public static var logger: Logging.Logger? = {
		return Logger(label: "com.xcode-actions.XcodeTools")
	}()
	
}

typealias Conf = XcodeToolsConfig
