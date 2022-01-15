import Foundation

import Logging



/** A container to hold the properties that can modify the behaviour of the module. */
public enum SPMProjConfig {
	
	/**
	 Everything ``SPMProj`` logs will go through this logger.
	 
	 This property is wrapped in a `TaskLocal`, which means you can change it in a particular task using `$logger.withValue(...)`.
	 
	 If you use a `TaskLocal` logger in your app, you can assign the *wrapper* value of the logger using ``setLogger(wrappedLogger:)``. */
	@TaskLocal
	public static var logger: Logger? = .init(label: "com.xcode-actions.XcodeProj")
	/**
	 Sets the *wrapper* of the logger directly.
	 
	 This allows synchronisation of your own `TaskLocal` logger with ``SPMProj``’s. */
	public static func setLogger(wrappedLogger: TaskLocal<Logger?>) {
		_logger = wrappedLogger
	}
	
}

typealias Conf = SPMProjConfig
