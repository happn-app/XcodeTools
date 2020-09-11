import CoreData
import Foundation



/* From http://www.monobjc.net/xcode-project-file-format.html */
@objc(PBXFileElement)
public class PBXFileElement : PBXObject {
	
	public enum SourceTree {
		
		init(_ string: String) {
			switch string {
				case "<group>":    self = .group
				case "<unknown>":  self = .unknown
				case "<absolute>": self = .absolute
				default:           self = .variable(string)
			}
		}
		
		case group
		case unknown
		case absolute
		
		/* Known possible variables:
		 *    - SDKROOT
		 *    - SOURCE_ROOT
		 *    - DEVELOPER_DIR
		 *    - BUILT_PRODUCTS_DIR */
		case variable(String)
		
	}
	
	public override class func propertyRenamings() -> [String : String] {
		let mine = [
			"rawName": "name",
			"rawPath": "path",
			"rawSourceTree": "sourceTree"
		]
		return super.propertyRenamings().merging(mine, uniquingKeysWith: { current, new in
			precondition(current == new, "Incompatible property renamings")
			NSLog("%@", "Warning: Internal logic shadiness: Property rename has been declared twice for destination \(current), in class \(self)")
			return current
		})
	}
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		rawSourceTree = try rawObject.get("sourceTree")
		
		rawName = try rawObject.getIfExists("name")
		rawPath = try rawObject.getIfExists("path")
		
		if let indentWidthStr: String = try rawObject.getIfExists("indentWidth") {
			guard let value = Int16(indentWidthStr) else {
				throw HagvtoolError(message: "Unexpected indent width value \(indentWidthStr) in object \(id ?? "<unknown>")")
			}
			indentWidth = NSNumber(value: value)
		}
		if let tabWidthStr: String = try rawObject.getIfExists("tabWidth") {
			guard let value = Int16(tabWidthStr) else {
				throw HagvtoolError(message: "Unexpected tab width value \(tabWidthStr) in object \(id ?? "<unknown>")")
			}
			tabWidth = NSNumber(value: value)
		}
		if let usesTabsStr: String = try rawObject.getIfExists("usesTabs") {
			guard let value = Int16(usesTabsStr) else {
				throw HagvtoolError(message: "Unexpected uses tabs value \(usesTabsStr)")
			}
			if value != 0 && value != 1 {
				NSLog("%@", "Warning: Unknown value for usesTabs \(usesTabsStr) in object \(id ?? "<unknown>"); expecting 0 or 1; setting to true.")
			}
			usesTabs = NSNumber(value: value != 0)
		}
		if let wrapsLinesStr: String = try rawObject.getIfExists("wrapsLines") {
			guard let value = Int16(wrapsLinesStr) else {
				throw HagvtoolError(message: "Unexpected wraps lines value \(wrapsLinesStr)")
			}
			if value != 0 && value != 1 {
				NSLog("%@", "Warning: Unknown value for wrapsLines \(wrapsLinesStr) in object \(id ?? "<unknown>"); expecting 0 or 1; setting to true.")
			}
			wrapsLines = NSNumber(value: value != 0)
		}
	}
	
	var name: String? {
		rawName ?? rawPath
	}
	
	var path: String? {
		rawPath ?? rawName
	}
	
	var sourceTree: SourceTree? {
		return rawSourceTree.flatMap{ SourceTree($0) }
	}
	
	/**
	The given resolved path is relative to the xcodeproj path if the returned
	`rootVar` is nil. */
	var resolvedPathInfo: (rootVar: String?, path: String)? {
		guard let sourceTree = sourceTree else {
			return nil
		}
		
		switch sourceTree {
			case .group:
				if let parent = parent {
					return parent.resolvedPathInfo.flatMap{
						let (rootVar, parentPath) = $0
						if !parentPath.isEmpty {return (rootVar, parentPath + (path.flatMap{ "/" + $0 } ?? ""))}
						else                   {return (rootVar, path ?? "")}
					}
				} else {
					guard let project = (self as? PBXGroup)?.projectForMainGroup else {
						print("Warning: Got asked the resolved path of a file element without a parent, whose projectForMainGroup property is nil (not the main group), and whose source tree is <group>. This is weird and I don’t know how to handle this; returning nil.")
						return nil
					}
					/* I don’t know the role of project.projectRoot. I tried
					 * modifying it on a project, it didn’t change anything I could
					 * see, but idk… */
					switch (project.projectDirPath, path) {
						case (let dirPath?, let path?):
							if dirPath.isEmpty   {return (nil, path)}
							else if path.isEmpty {return (nil, dirPath)}
							else                 {return (nil, dirPath + "/" + path)}
							
						case (let path?, nil), (nil, let path?):
							return (nil, path)
							
						case (nil, nil):
							return (nil, "")
					}
				}
				
			case .absolute:
				guard let path = path else {
					return nil
				}
				if !path.starts(with: "/") {
					print("Warning: Got an absolute source tree in \(id ?? "<unknown object>"), but file element path does not start w/ a slash!")
				}
				return (nil, path)
				
			case .unknown:
				print("Warning: Asked resolved path of a file element whose source tree is unknown! Returning nil.")
				/* I guess? */
				return nil
				
			case .variable(let variable):
				return (variable, path ?? ".")
		}
	}
	
	public func resolvedPathAsURL(xcodeprojURL: URL, variables: [String: String] = [:]) throws -> URL {
		func relativeToXcodeproj(_ path: String) -> URL {
			let projectURL = xcodeprojURL.deletingLastPathComponent()
			guard !path.isEmpty else {return projectURL}
			
			return URL(fileURLWithPath: path, relativeTo: projectURL)
		}
		
		switch resolvedPathInfo {
			case nil:
				throw HagvtoolError(message: "Cannot get resolved path info.")
				
			case (let rootVar?, let path)?:
				guard let varValue = variables[rootVar] else {
					throw HagvtoolError(message: "Cannot resolve the resovled path info because I do not have a value for variable \(rootVar).")
				}
				if varValue.isEmpty  {return relativeToXcodeproj(path)}
				else if path.isEmpty {return relativeToXcodeproj(varValue)}
				else                 {return relativeToXcodeproj(varValue + "/" + path)}
				
			case (_/*nil actually*/, let path)?:
				return relativeToXcodeproj(path)
		}
	}
	
}
