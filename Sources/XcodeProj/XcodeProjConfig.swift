import Foundation

import Logging



public struct XcodeProjConfig {
	
	/**
	Set to true to allow allocate unknown objects as `PBXObjects`.
	
	If set to `false`, trying to allocate unknown objects will throw an error. */
	public static var allowPBXObjectAllocation = false
	
	public static var logger: Logging.Logger? = {
		return Logger(label: "com.xcode-actions.XcodeProj")
	}()
	
	/** This struct is simply a container for static configuration properties. */
	private init() {}
	
}
