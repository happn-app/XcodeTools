/*
 * Objects.swift
 * hagvtool
 *
 * Created by François Lamboley on 1/1/17.
 * Copyright © 2017 happn. All rights reserved.
 */

import Foundation



enum LogType {
	
	case quiet
	case humanReadable
	case porcelain
	case json /* Not implemented */
	
}



struct BuildConfig {
	
	enum VersioningSystem {
		case appleGeneric
		case none
		case unknown
		
		init(fromBuildSetting buildSetting: String?) {
			switch buildSetting {
			case "apple-generic"?: self = .appleGeneric
			case ""?, nil:         self = .none
			default:               self = .unknown
			}
		}
	}
	
	struct Misconfigs : Equatable, Hashable {
		
		var noInfoPlist: Bool = false
		var unreadablePlistPath: String? = nil
		var cannotReadInfoPlist: Bool {return unreadablePlistPath == nil}
		
		var noBuildNumberInPlist: Bool = false
		var noMarketingNumberInPlist: Bool = false
		
		var noAppleVersioning: Bool = false
		
		var diffBuildNumbers: (projectConf: String, infoPlist: String)? = nil
		
		func filtered(mask: Misconfigs) -> Misconfigs {
			return Misconfigs(
				noInfoPlist: noInfoPlist && mask.noInfoPlist,
				unreadablePlistPath: mask.unreadablePlistPath != nil ? unreadablePlistPath : nil,
				noBuildNumberInPlist: noBuildNumberInPlist && mask.noBuildNumberInPlist,
				noMarketingNumberInPlist: noMarketingNumberInPlist && mask.noMarketingNumberInPlist,
				noAppleVersioning: noAppleVersioning && mask.noAppleVersioning,
				diffBuildNumbers: mask.diffBuildNumbers != nil ? diffBuildNumbers : nil
			)
		}
		
		var hashValue: Int {
			return (
				(noInfoPlist              ? 0 : 1) * 0x1  +
				(cannotReadInfoPlist      ? 0 : 1) * 0x10 +
				(noBuildNumberInPlist     ? 0 : 1) * 0x100 +
				(noMarketingNumberInPlist ? 0 : 1) * 0x1000 +
				(noAppleVersioning        ? 0 : 1) * 0x10000 +
				(diffBuildNumbers != nil  ? 0 : 1) * 0x100000
			)
		}
		
		static func ==(_ lhs: Misconfigs, _ rhs: Misconfigs) -> Bool {
			return (
				lhs.noInfoPlist == rhs.noInfoPlist &&
				lhs.cannotReadInfoPlist == rhs.cannotReadInfoPlist &&
				lhs.noBuildNumberInPlist == rhs.noBuildNumberInPlist &&
				lhs.noMarketingNumberInPlist == rhs.noMarketingNumberInPlist &&
				lhs.noAppleVersioning == rhs.noAppleVersioning &&
				(lhs.diffBuildNumbers != nil) == (rhs.diffBuildNumbers != nil)
			)
		}
		
	}
	
	enum BuildNumber : Equatable, Hashable {
		
		case none
		case bothEqual(String)
		case config(String)
		case plist(String)
		case both(config: String, plist: String)
		
		func reduced() -> String? {
			switch self {
			case .none, .both: return nil
			case .bothEqual(let v), .config(let v), .plist(let v): return v
			}
		}
		
		func filtered(keepConfig: Bool, keepPlist: Bool) -> BuildNumber {
			switch (self, keepConfig, keepPlist) {
			case (.none,                          _,     _):     return .none
			case (.bothEqual(let v),              true,  false): return .config(v)
			case (.bothEqual(let v),              false, true):  return .plist(v)
			case (.both(config: let v, plist: _), true,  false): return .config(v)
			case (.both(config: _, plist: let v), false, true):  return .plist(v)
			case (.config,                        true,  _):     return self
			case (.config,                        false, _):     return .none
			case (.plist,                         _,     true):  return self
			case (.plist,                         _,     false): return .none
			case (_,                              false, false): return .none
			case (_,                              true,  true):  return self
			default: fatalError("Internal Logic Error") /* Swift considers the switch is not exhaustive. I do not agree! */
			}
		}
		
		var hashValue: Int {
			switch self {
			case .none: return 0
			case .bothEqual(let v):                    return v.hashValue                    &* 0x1
			case .config(let v):                       return v.hashValue                    &* 0x10
			case .plist(let v):                        return v.hashValue                    &* 0x100
			case .both(config: let vc, plist: let vp): return (vc.hashValue &+ vp.hashValue) &* 0x1000
			}
		}
		
		static func ==(_ lhs: BuildNumber, _ rhs: BuildNumber) -> Bool {
			switch (lhs, rhs) {
			case (.none, .none):                                     return true
			case (.bothEqual(let vl),      .bothEqual(let vr)):      return vl == vr
			case (.config(let vl),         .config(let vr)):         return vl == vr
			case (.plist(let vl),          .plist(let vr)):          return vl == vr
			case (.both(let cvl, let pvl), .both(let cvr, let pvr)): return cvl == cvr && pvl == pvr
			default: return false
			}
		}
		
	}
	
	let ref: String
	
	let name: String
	let productName: String
	
	let infoPlistPath: String? /* For informative purpose */
	let infoPlistFormat: PropertyListSerialization.PropertyListFormat? /* nil if plist is unreadable */
	
	var infoPlistBuildNumber: String?
	var infoPlistMarketingVersion: String?
	
	var versioningSystem: VersioningSystem
	var buildNumber: String?
	
	let versioningSourceFilename: String
	let versioningPrefix: String
	let versioningSuffix: String
	
	let versioningUsername: String? /* What's the use? */
	let versioningExportDeclaration: String? /* Unused in our case. */
	
	/* When needing to rewrite build settings */
	var fullBuildSettings: [String: Any]
	
	/* When needing to rewrite the plist */
	let infoPlistURL: URL?
	var infoPlistContent: [String: Any]?
	
	/* Would prefer lazy var, but invalidates default initializer and too lazy to
	 * re-create the initializer... */
	var misconfigs: Misconfigs {
		var res = Misconfigs()
		
		switch (infoPlistPath, infoPlistFormat) {
		case (nil, _):
			res.noInfoPlist = true
			
		case (.some(let path), nil):
			res.unreadablePlistPath = path
			
		case (.some, .some):
			res.noBuildNumberInPlist = (infoPlistBuildNumber == nil)
			res.noMarketingNumberInPlist = (infoPlistMarketingVersion == nil)
		}
		
		if versioningSystem != .appleGeneric {res.noAppleVersioning = true}
		else if buildNumber?.isEmpty ?? true {res.noAppleVersioning = true}
		
		if let infoPlistBuildNumber = infoPlistBuildNumber, let buildNumber = buildNumber, infoPlistBuildNumber != buildNumber {
			res.diffBuildNumbers = (projectConf: buildNumber, infoPlist: infoPlistBuildNumber)
		}
		
		return res
	}
	
	var fullBuildNumber: BuildNumber {
		switch (buildNumber, infoPlistBuildNumber) {
		case (.some(let bn), .some(let ibn)) where bn == ibn: return .bothEqual(bn)
		case (.some(let bn), .some(let ibn)):                 return .both(config: bn, plist: ibn)
		case (.some(let bn), nil):                            return .config(bn)
		case (nil,           .some(let ibn)):                 return .plist(ibn)
		case (nil,           nil):                            return .none
		}
	}
	
}



struct Target {
	
	let name: String
	var buildConfigs: [BuildConfig]
	
	var misconfiguredBuildConfigs: [BuildConfig] {
		return buildConfigs.filter { $0.misconfigs != BuildConfig.Misconfigs() }
	}
	
	func misconfiguredBuildConfigs(matchingMisconfigsMask mask: BuildConfig.Misconfigs) -> [BuildConfig] {
		return buildConfigs.filter { return $0.misconfigs.filtered(mask: mask) != BuildConfig.Misconfigs() }
	}
	
	var distinctMisconfigurations: [BuildConfig.Misconfigs] {
		return Array(Set(buildConfigs.map { $0.misconfigs }))
	}
	
	func distinctMisconfigurations(matchingMisconfigsMask mask: BuildConfig.Misconfigs) -> [BuildConfig.Misconfigs] {
		return Array(Set(buildConfigs.map { $0.misconfigs.filtered(mask: mask) }))
	}
	
	var distinctActualMisconfigurations: [BuildConfig.Misconfigs] {
		return Array(Set(misconfiguredBuildConfigs.map {$0.misconfigs}))
	}
	
	func distinctActualMisconfigurations(matchingMisconfigsMask mask: BuildConfig.Misconfigs) -> [BuildConfig.Misconfigs] {
		return Array(Set(misconfiguredBuildConfigs(matchingMisconfigsMask: mask).map {$0.misconfigs}))
	}
	
	func doAllOrNoneOfBuildConfigsHaveMisconfigsMask(_ mask: BuildConfig.Misconfigs) -> Bool {
		let matchingMisconfiguredCount = misconfiguredBuildConfigs(matchingMisconfigsMask: mask).count
		return matchingMisconfiguredCount == 0 || matchingMisconfiguredCount == buildConfigs.count
		/* or */
		//		let dcfgs = distinctMisconfigurations(matchingMisconfigsMask: mask)
		//		return (!dcfgs.contains(BuildConfig.Misconfigs()) || dcfgs.count == 1)
	}
	
	var distinctBuildNumbers: [String?] {
		let buildNumbers = buildConfigs.map { $0.fullBuildNumber.reduced() }
		let hasNil = buildNumbers.contains(where: { $0 == nil })
		let nonNilBuildNumbers = buildNumbers.flatMap { $0 }
		return Array(Set(nonNilBuildNumbers)) + (hasNil ? [nil] : [])
	}
	
	var distinctMarketingVersions: [String?] {
		let marketingVersions = buildConfigs.map { $0.infoPlistMarketingVersion }
		let hasNil = marketingVersions.contains(where: { $0 == nil })
		let nonNilMarketingVersions = marketingVersions.flatMap { $0 }
		return Array(Set(nonNilMarketingVersions)) + (hasNil ? [nil] : [])
	}
	
	static func pbxprojURLFromProject(url: URL) -> URL {
		return URL(fileURLWithPath: "project.pbxproj", isDirectory: false, relativeTo: url)
	}
	
	static func targetsFromProject(url projectURL: URL, targetsCriteria: [NSRegularExpression]?) -> [Target]? {
		let pbxprojURL = pbxprojURLFromProject(url: projectURL)
		
		/* Checking the pbxproj file exists */
		var isDir: ObjCBool = true
		guard FileManager.default.fileExists(atPath: pbxprojURL.path, isDirectory: &isDir) && !isDir.boolValue else {
			print("project.pbxproj does not exist or is a directory", to: &mx_stderr)
			return nil
		}
		
		/* Reading pbxproj file */
		guard let pbxprojData = try? Data(contentsOf: pbxprojURL) else {
			print("Cannot read contents of pbxproj file (\(pbxprojURL))", to: &mx_stderr)
			return nil
		}
		
		/* Deserializing the pbxproj */
		//var format = PropertyListSerialization.PropertyListFormat.xml
		guard let pbxprojUnarchived = (try? PropertyListSerialization.propertyList(from: pbxprojData, options: [], format: nil/*&format*/)) as? [String: Any], let pbxprojObjects = pbxprojUnarchived["objects"] as? [String: Any] else {
			print("Cannot deserialize contents of pbxproj file (\(pbxprojURL))", to: &mx_stderr)
			return nil
		}
		/* Now, "format" is (should be) PropertyListSerialization.PropertyListFormat.openStep */
		
		/* Resolving root object from pbxproj */
		guard let pbxprojObjectRef = pbxprojUnarchived["rootObject"] as? String, let pbxprojObject = pbxprojObjects[pbxprojObjectRef] as? [String: Any], pbxprojObject["isa"] as? String == "PBXProject" else {
			print("Unexpected content of pbxproj file (\(pbxprojURL)): rootObject is undefined, or corresponding object does not exist, or is not (isa) a PBXProject", to: &mx_stderr)
			return nil
		}
		
		/* We can now compute the project "dir" path, which is the root from which Xcode will fetch relative path (seems to be at least) */
		let projectDirPath = URL(fileURLWithPath: pbxprojObject["projectDirPath"] as? String ?? "", isDirectory: true, relativeTo: URL(fileURLWithPath: "..", isDirectory: true, relativeTo: project_url))
		
		/* To retrieve the targets, we first get the refs of the project's targets */
		guard let targetRefs = pbxprojObject["targets"] as? [String] else {
			print("Cannot list targets of project from pbxproj file (\(pbxprojURL))", to: &mx_stderr)
			return nil
		}
		
		var targets = [Target]()
		for targetRef in targetRefs {
			/* Let's fetch the object for the current target ref */
			guard let targetObject = pbxprojObjects[targetRef] as? [String: Any] else {
				print("Cannot get target object for ref \(targetRef) from pbxproj file (\(pbxprojURL))", to: &mx_stderr)
				return nil
			}
			/* Only native targets are considered */
			guard targetObject["isa"] as? String == "PBXNativeTarget" else {continue}
			
			/* Retrieving the name of the target */
			guard let targetName = targetObject["name"] as? String else {
				print("Cannot get target name from target ref \(targetRef) from pbxproj file (\(pbxprojURL))", to: &mx_stderr)
				return nil
			}
			/* Let's match the target's name to the criteria given by the user */
			if let targetsCriteria = targetsCriteria {
				var match = false
				let targetNameRange = NSRange(location: 0, length: (targetName as NSString).length)
				for targetsCriterion in targetsCriteria {
					targetsCriterion.enumerateMatches(in: targetName, options: [.anchored], range: targetNameRange) { result, flags, stop in
						guard let result = result else {return}
						if result.range.location == targetNameRange.location && result.range.length == targetNameRange.length {
							stop.pointee = ObjCBool(true)
							match = true
						}
					}
					if match {break}
				}
				/* If we do not match, this target do not pass the given criteria; we skip it! */
				guard match else {continue}
			}
			
			/* The configuration list is an object which contains basically a list of configuarations (surprising, isn't it?) */
			guard let buildConfigurationListRef = targetObject["buildConfigurationList"] as? String else {
				print("Cannot get build configuration list ref for target ref \(targetRef) from pbxproj file (\(pbxprojURL))", to: &mx_stderr)
				return nil
			}
			/* Let's get the actual configuration list from its ref, and check we actually get a (isa) "XCConfigurationList" object */
			guard let buildConfigurationListObject = pbxprojObjects[buildConfigurationListRef] as? [String: Any], buildConfigurationListObject["isa"] as? String == "XCConfigurationList" else {
				print("Cannot get build configuration list object from ref \(buildConfigurationListRef) for target ref \(targetRef) from pbxproj file (\(pbxprojURL))", to: &mx_stderr)
				return nil
			}
			/* We can now retrieve the configurations ref from the list object */
			guard let buildConfigurationRefs = buildConfigurationListObject["buildConfigurations"] as? [String] else {
				print("Cannot get build configuration refs from build configuration list from ref \(buildConfigurationListRef) for target ref \(targetRef) from pbxproj file (\(pbxprojURL))", to: &mx_stderr)
				return nil
			}
			var buildConfigurations = [BuildConfig]()
			for buildConfigurationRef in buildConfigurationRefs {
				/* We retrieve the actual configuration object (and check it's actually a (isa) "XCBuildConfiguration") */
				guard let buildConfigurationObject = pbxprojObjects[buildConfigurationRef] as? [String: Any], buildConfigurationObject["isa"] as? String == "XCBuildConfiguration" else {
					print("Cannot get build configuration object from ref \(buildConfigurationRef) from build configuration list from ref \(buildConfigurationListRef) for target ref \(targetRef) from pbxproj file (\(pbxprojURL))", to: &mx_stderr)
					return nil
				}
				/* We need the name of the configuration */
				guard let buildConfigurationName = buildConfigurationObject["name"] as? String else {
					print("Cannot get build configuration name from build configuration object from ref \(buildConfigurationRef) from build configuration list from ref \(buildConfigurationListRef) for target ref \(targetRef) from pbxproj file (\(pbxprojURL))", to: &mx_stderr)
					return nil
				}
				/* The build settings of the configuration will give us all the versioning info we need. Note, as said at the
				 * beginning of the project, we don't actually resolve the build settings. Only the "direct" settings of the
				 * target are considered. If a project has some versioning information configured at the project level, or in
				 * configuration files, they will be ignored. */
				guard let buildSettings = buildConfigurationObject["buildSettings"]  as? [String: Any] else {
					print("Cannot get build settings from build configuration object from ref \(buildConfigurationRef) from build configuration list from ref \(buildConfigurationListRef) for target ref \(targetRef) from pbxproj file (\(pbxprojURL))", to: &mx_stderr)
					return nil
				}
				let versioningSystem = BuildConfig.VersioningSystem(fromBuildSetting: buildSettings["VERSIONING_SYSTEM"] as? String)
				let buildNumber = buildSettings["CURRENT_PROJECT_VERSION"] as? String
				let productName = (buildSettings["PRODUCT_NAME"] as? String ?? "$(TARGET_NAME)").replacingOccurrences(of: "$(TARGET_NAME)", with: targetName).replacingOccurrences(of: "${TARGET_NAME}", with: targetName)
				let versioningSourceFilename = buildSettings["VERSION_INFO_FILE"] as? String
				let versioningPrefix = buildSettings["VERSION_INFO_PREFIX"] as? String
				let versioningSuffix = buildSettings["VERSION_INFO_SUFFIX"] as? String
				let versioningUsername = buildSettings["VERSION_INFO_BUILDER"] as? String
				let versioningExportDeclaration = buildSettings["VERSION_INFO_EXPORT_DECL"] as? String
				let infoPlistPath = (buildSettings["INFOPLIST_FILE"] as? String)?.replacingOccurrences(of: "$(SRCROOT)", with: projectDirPath.path).replacingOccurrences(of: "${SRCROOT}", with: projectDirPath.path)
				let infoPlistMarketingVersion: String?
				let infoPlistBuildNumber: String?
				let infoPlistFormat: PropertyListSerialization.PropertyListFormat?
				let infoPlistContent: [String: Any]?
				let infoPlistURL: URL?
				
				do {
					/* Now to parse the Info.plist file! */
					guard let infoPlistPath = infoPlistPath else {throw NSError()}
					
					let plistURL = URL(fileURLWithPath: infoPlistPath, isDirectory: false, relativeTo: projectDirPath)
					guard let stream = InputStream(url: plistURL) else {throw NSError()}
					stream.open(); defer {stream.close()}
					
					var format = PropertyListSerialization.PropertyListFormat.xml
					guard let plistUnarchived = try PropertyListSerialization.propertyList(with: stream, options: [], format: &format) as? [String: Any] else {throw NSError()}
					
					infoPlistURL = plistURL
					infoPlistFormat = format
					infoPlistContent = plistUnarchived
					infoPlistBuildNumber = plistUnarchived["CFBundleVersion"] as? String
					infoPlistMarketingVersion = plistUnarchived["CFBundleShortVersionString"] as? String
				} catch {
					infoPlistMarketingVersion = nil
					infoPlistBuildNumber = nil
					infoPlistContent = nil
					infoPlistFormat = nil
					infoPlistURL = nil
				}
				let buildConfig = BuildConfig(
					ref: buildConfigurationRef,
					name: buildConfigurationName,
					productName: productName,
					infoPlistPath: infoPlistPath,
					infoPlistFormat: infoPlistFormat,
					infoPlistBuildNumber: infoPlistBuildNumber,
					infoPlistMarketingVersion: infoPlistMarketingVersion,
					versioningSystem: versioningSystem,
					buildNumber: buildNumber,
					versioningSourceFilename: versioningSourceFilename ?? productName + "_vers.c",
					versioningPrefix: versioningPrefix ?? "",
					versioningSuffix: versioningSuffix ?? "",
					versioningUsername: versioningUsername,
					versioningExportDeclaration: versioningExportDeclaration,
					fullBuildSettings: buildSettings,
					infoPlistURL: infoPlistURL,
					infoPlistContent: infoPlistContent
				)
				buildConfigurations.append(buildConfig)
			}
			let target = Target(name: targetName, buildConfigs: buildConfigurations)
			targets.append(target)
		}
		return targets
	}
	
}
