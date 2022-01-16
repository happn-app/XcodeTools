import Foundation



public enum XcodeUtils {
	
	public static func stringToSafeSwiftVarName(_ str: String) -> String? {
		/* Remove diacritics and co, convert emoji and other to latin.
		 * Note that most of this is probably unneeded for Swift as it fully supports UTF-8. */
		guard var safeStr = str
					.applyingTransform(.stripCombiningMarks, reverse: false)?
					.applyingTransform(.stripDiacritics, reverse: false)?
					.applyingTransform(.toLatin, reverse: false)
		else {
			return nil
		}
		
		/* Remove anything non-ascii and non-letters and non-number. */
		safeStr.removeAll(where: { !$0.isASCII || (!$0.isLetter && !$0.isNumber) })
		
		/* Remove leading digits (a variable name cannot start with a digit). */
		guard let notNumberIdx = safeStr.firstIndex(where: { !$0.isNumber }) else {
			/* The string only contains numbers or is empty. */
			return nil
		}
		safeStr.removeSubrange(safeStr.startIndex..<notNumberIdx)
		
		/* Lowercase first char of variable name.
		 * This is not required per-se, but all Swift variable names start with a lowercase letter almost everywhere. */
		if let f = safeStr.first, f.isUppercase {
			safeStr = safeStr.replacingCharacters(
				in: safeStr.startIndex..<safeStr.index(after: safeStr.startIndex),
				with: f.lowercased()
			)
		}
		
		return safeStr
	}
	
}
