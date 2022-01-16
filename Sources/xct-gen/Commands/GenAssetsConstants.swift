import Foundation

import ArgumentParser
import SystemPackage
import XcodeTools
import XibLoc



struct GenAssetsConstants : ParsableCommand {
	
	static var configuration = CommandConfiguration(
		commandName: "assets-constants",
		abstract: "Generates the constants from the xcasset.",
		discussion: "Generate a Swift file containing constants derived from the xcassets in your project."
	)
	
	@OptionGroup
	var xctGenOptions: XctGen.Options
	
	@Argument
	var generatedFilePathTemplate: String
	
	@Argument
	var targets = [String]()
	
	func run() throws {
		let colorsetIncludeRegex = try! NSRegularExpression(pattern: #".*\.colorset$"#, options: [.caseInsensitive])
		
		let project = try Project(xcodeprojPath: xctGenOptions.pathToXcodeproj)
		for target in try project.getTargets() {
			let targetName = try target.getName()
			let isSPMTarget = (target.spmTarget != nil)
			guard targets.isEmpty || targets.contains(targetName) else {
				continue
			}
			guard !(target.spmTarget?.sourcesContainsObjCFiles ?? false) else {
//				Conf.logger?.info("Skipped target \(targetName) which contains ObjC.")
				continue
			}
			
			let resolvingInfo = Str2StrXibLocInfo(replacements: ["|": targetName], orderedReplacements: ["<:>": !isSPMTarget ? 0 : 1])!
			let relativeDest = generatedFilePathTemplate.applying(xibLocInfo: resolvingInfo)
			
			/* Get the color names. */
			var colorNames = [String: String]()
			for resourceURL in try target.getResources() {
				guard resourceURL.pathExtension == "xcassets", let assetsPath = FilePath(resourceURL) else {
					continue
				}
				
				try FileManager.default.iterateFiles(in: assetsPath, include: [colorsetIncludeRegex], handler: { _, relativePath, isDir in
					guard let colorName = relativePath.stem else {
						return true
					}
					/* Note: We’re aggressive in name normalization. Swift would accept accents, emoji and co. */
					guard var swiftColorName = colorName
						.applyingTransform(.stripCombiningMarks, reverse: false)?
						.applyingTransform(.stripDiacritics, reverse: false)?
						.applyingTransform(.toLatin, reverse: false)
					else {
						throw XctGenError(message: "Cannot convert color name \(colorName) to Swift-safe var name.")
					}
					
					swiftColorName.removeAll(where: { !$0.isASCII || (!$0.isLetter && !$0.isNumber) })
					guard let notNumberIdx = swiftColorName.firstIndex(where: { !$0.isNumber }) else {
						throw XctGenError(message: "Normalized color name \(colorName) only contains numbers or is empty. Cannot create Swift-safe var name.")
					}
					swiftColorName.removeSubrange(swiftColorName.startIndex..<notNumberIdx)
					if let f = swiftColorName.first, f.isUppercase {
						swiftColorName = swiftColorName.replacingCharacters(
							in: swiftColorName.startIndex..<swiftColorName.index(after: swiftColorName.startIndex),
							with: f.lowercased()
						)
					}
					guard colorNames[swiftColorName] == nil else {
						throw XctGenError(message: "Got normalized color name \(swiftColorName) twice!")
					}
					colorNames[swiftColorName] = colorName
					return true
				})
			}
			
			/* Write or remove assets file. */
			let dest = URL(fileURLWithPath: relativeDest, relativeTo: target.getSourcesRoot())
			if colorNames.isEmpty {
				_ = try? FileManager.default.removeItem(at: dest)
			} else {
				var generatedFile = """
					import Foundation
					import UIKit
					
					
					
					internal struct XctAssetsConstants {
						
					"""
				for (swiftColorName, colorName) in colorNames.sorted(by: { $0.key < $1.key }) {
					var openQuote = "\""
					var closeQuote = "\""
					while colorName.contains(openQuote) || colorName.contains(closeQuote) {
						openQuote = "#" + openQuote
						closeQuote = closeQuote + "#"
					}
					generatedFile += #"""
						
							internal static let \#(swiftColorName) = UIColor(named: \#(openQuote)\#(colorName)\#(closeQuote)\#(!isSPMTarget ? "" : ", in: .module, compatibleWith: nil"))!
						"""#
				}
				generatedFile += """
					
						
					}
					
					"""
				try FileManager.default.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
				try Data(generatedFile.utf8).write(to: dest)
			}
		}
	}
	
}
