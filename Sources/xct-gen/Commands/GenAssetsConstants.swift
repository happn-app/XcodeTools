import Foundation

import ArgumentParser
import SPMProj
import SystemPackage
import XcodeProj



struct GenAssetsConstants : ParsableCommand {
	
	static var configuration = CommandConfiguration(
		commandName: "assets-constants",
		abstract: "Generates the constants from the xcasset.",
		discussion: "Generate a Swift file containing constants derived from the xcassets in your project."
	)
	
	@OptionGroup
	var xctVersionsOptions: XctGen.Options
	
	@Flag
	var targetIsModulePath: Bool = false
	
	@Argument
	var targetAndFileTuples: [String]
	
	func validate() throws {
		guard !targetAndFileTuples.isEmpty && targetAndFileTuples.count.isMultiple(of: 2) else {
			throw XctGenError(message: "Invalid number for arguments for target and files tuples")
		}
	}
	
	func run() throws {
		var targetToDestFiles = [String: [String]]()
		for idx in stride(from: targetAndFileTuples.startIndex, to: targetAndFileTuples.endIndex, by: 2) {
			let target = targetAndFileTuples[idx]
			let destinationFile = targetAndFileTuples[idx+1]
			targetToDestFiles[target, default: []].append(destinationFile)
		}
		
		let includeRegex = try! NSRegularExpression(pattern: #".*\.colorset$"#, options: [.caseInsensitive])
		try iterateTargetsFiles{ target in
			targetToDestFiles[target]
		} fillColorNamesAssets: { assetsPath, colorNames in
			try FileManager.default.iterateFiles(in: assetsPath, include: [includeRegex], handler: { _, relativePath, isDir in
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
		} writeFile: { colorNames, destURL in
			var generatedFile = """
				import Foundation
				import UIKit
				
				
				
				public struct XctAssetsConstants {
					
				"""
			for (swiftColorName, colorName) in colorNames.sorted(by: { $0.key < $1.key }) {
				/* For now we assume colorName won’t contain #" */
				var openQuote = "\""
				var closeQuote = "\""
				while colorName.contains(openQuote) || colorName.contains(closeQuote) {
					openQuote = "#" + openQuote
					closeQuote = closeQuote + "#"
				}
				generatedFile += #"""
					
						public static let \#(swiftColorName) = UIColor(named: \#(openQuote)\#(colorName)\#(closeQuote)\#(!targetIsModulePath ? "" : ", in: .module, compatibleWith: nil"))!
					"""#
			}
			generatedFile += """
				
					
				}
				
				"""
			try Data(generatedFile.utf8).write(to: destURL)
		}
	}
	
	private func iterateTargetsFiles(destFilesForTarget: (String) -> [String]?, fillColorNamesAssets: (FilePath, inout [String: String]) throws -> Void, writeFile: ([String: String], URL) throws -> Void) throws {
		if !targetIsModulePath {
			let xcodeproj = try XcodeProj(path: xctVersionsOptions.pathToXcodeproj, autodetectInFolderAtPath: ".")
			try xcodeproj.managedObjectContext.performAndWait{
				for target in try xcodeproj.pbxproj.rootObject.getTargets() {
					guard let destinationFiles = try destFilesForTarget(target.getName()) else {
						continue
					}
					var colorNames = [String: String]()
					for buildPhase in try target.getBuildPhases() {
						guard let resPhase = buildPhase as? PBXResourcesBuildPhase else {
							continue
						}
						for file in try resPhase.getFiles() {
							guard
								let url = try? file.fileRef?.resolvedPathAsURL(xcodeprojURL: xcodeproj.xcodeprojURL, variables: [:]),
								url.pathExtension == "xcassets"
							else {
								continue
							}
							guard let filePath = FilePath(url) else {
								throw XctGenError(message: "Internal error: Cannot generate FilePath for URL \(url.absoluteString)")
							}
							try fillColorNamesAssets(filePath, &colorNames)
						}
					}
					for destinationFile in destinationFiles {
						try writeFile(colorNames, URL(fileURLWithPath: destinationFile, relativeTo: xcodeproj.xcodeprojURL.deletingLastPathComponent()))
					}
				}
			}
		} else {
//			let spmProj = try SPMProj(path: ".")
			/* For now SPMProj does not know how to do anything, so we just do it manually. */
			for targetURL in try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: "Sources"), includingPropertiesForKeys: nil) {
				let targetName = targetURL.lastPathComponent
				guard let destinationFiles = destFilesForTarget(targetName) else {
					continue
				}
				var colorNames = [String: String]()
				let includeRegex = try! NSRegularExpression(pattern: #".*\.xcassets$"#, options: [.caseInsensitive])
				guard let filePath = FilePath(targetURL) else {
					throw XctGenError(message: "Internal error: Cannot generate FilePath for URL \(targetURL.absoluteString)")
				}
				try FileManager.default.iterateFiles(in: filePath, include: [includeRegex], handler: { fullPath, _, isDir in
					guard isDir else {return true}
					try fillColorNamesAssets(fullPath, &colorNames)
					return true
				})
				for destinationFile in destinationFiles {
					try writeFile(colorNames, URL(fileURLWithPath: destinationFile, relativeTo: targetURL))
				}
			}
		}
	}
	
}
