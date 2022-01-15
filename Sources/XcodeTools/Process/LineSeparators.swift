import Foundation



public enum LineSeparators {
	
	case newLine(unix: Bool, legacyMacOS: Bool, windows: Bool)
	case customCharacters(Set<UInt8>)
	
	public static let `default` = LineSeparators.unix
	
	/** The whole output will be sent in one chunk. */
	public static let none = LineSeparators.customCharacters([])
	/** Suitable for outputs like `find ... -print0`. */
	public static let zero = LineSeparators.customCharacters([0x00])
	/** To get all bytes one by one (in EOL; lines will be empty). */
	public static let anything = LineSeparators.customCharacters(Set(UInt8.min...UInt8.max))
	/**
	 Suitable for standard unix utilities.
	 
	 Defined as `LineSeparators.newLine(unix: true, legacyMacOS: false, windows: false)`
	 but strictly equivalent to `.customCharacters([0x0a])`. */
	public static let unix = LineSeparators.newLine(unix: true, legacyMacOS: false, windows: false)
	public static let windows = LineSeparators.newLine(unix: false, legacyMacOS: false, windows: true)
	public static let anyNewLines = LineSeparators.newLine(unix: true, legacyMacOS: true, windows: true)
	
}
