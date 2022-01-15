import Foundation

import Logging



/** A container to hold the properties that can modify the behaviour of the module. */
public enum XcodeProjConfig {
	
	/**
	 Set to true to allow allocate unknown objects as `PBXObjects`.
	 
	 If set to `false`, trying to allocate unknown objects will throw an error. */
	public static var allowPBXObjectAllocation = false
	
	/**
	 Everything ``XcodeProj`` logs will go through this logger.
	 
	 This property is wrapped in a `TaskLocal`, which means you can change it in a particular task using `$logger.withValue(...)`.
	 
	 If you use a `TaskLocal` logger in your app, you can assign the *wrapper* value of the logger using ``setLogger(wrappedLogger:)``. */
	@TaskLocal
	public static var logger: Logger? = .init(label: "com.xcode-actions.XcodeProj")
	/**
	 Sets the *wrapper* of the logger directly.
	 
	 This allows synchronisation of your own `TaskLocal` logger with ``XcodeProj``’s. */
	public static func setLogger(wrappedLogger: TaskLocal<Logger?>) {
		_logger = wrappedLogger
	}
	
}

typealias Conf = XcodeProjConfig
