import Foundation

import Logging



public enum SourceBuilderConfig {
	
	@TaskLocal
	public static var logger: Logger = .init(label: "com.xcode-actions.SourceBuilder")
	
}

typealias Conf = SourceBuilderConfig
