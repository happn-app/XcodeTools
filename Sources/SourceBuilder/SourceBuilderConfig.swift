import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import Logging



/** A container to hold the properties that can modify the behaviour of the module. */
public enum SourceBuilderConfig {
	
	public static func registerBuildPhase(name: String, type: BuildPhase.Type) -> Bool {
		guard registeredBuildPhases[name] == nil else {
			logger?.error("Build phase “\(name)” is already registered. Ignoring new registration.")
			return false
		}
		registeredBuildPhases[name] = type
		return true
	}
	private static var registeredBuildPhases: [String: BuildPhase.Type] = [
		"download-file": DownloadFilePhase.self,
		"untar": UntarPhase.self
	]
	
	/**
	 The `FileManager` that will be used in ``SourceBuilder``.
	 
	 - Important: This property is not thread-safe. */
	public static var fm: FileManager = .default
	
	@TaskLocal
	public static var urlSession: URLSession = .shared
	
	/**
	 Everything ``SourceBuilder`` logs will go through this logger.
	 
	 This property is wrapped in a `TaskLocal`, which means you can change it in a particular task using `$logger.withValue(...)`.
	 
	 If you use a `TaskLocal` logger in your app, you can assign the *wrapper* value of the logger using ``setLogger(wrappedLogger:)``. */
	@TaskLocal
	public static var logger: Logger? = .init(label: "com.xcode-actions.SourceBuilder")
	/**
	 Sets the *wrapper* of the logger directly.
	 
	 This allows synchronisation of your own `TaskLocal` logger with ``SourceBuilder``’s. */
	public static func setLogger(wrappedLogger: TaskLocal<Logger?>) {
		_logger = wrappedLogger
	}
	
}

typealias Conf = SourceBuilderConfig
