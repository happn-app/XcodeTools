/*
 * main.swift
 * hagvtool
 *
 * Created by François Lamboley on 12/13/16.
 * Copyright © 2016 happn. All rights reserved.
 */

import Foundation
import CoreFoundation


/* Note: We only resolve configurations at level 1 (directly in target).
 * Xcode actually manages quite a few more levels. It has:
 *    - defaults (all empty for versioning)
 *    - project settings (retrieved via the "buildConfigurationList" key
 *      in the project object)
 *    - xcconfig file (retrieved via the "baseConfigurationReference" key
 *      in the config dictionary)
 *    - finally the configuration (the only level we currently process)
 */


/* Outputs & Behaviours:

Note: FYI, the singular of criteria is criterion.

print-build-number
------------------
STDOUT: Using pbxproj file <pbxproj path>
STDOUT: Found <n> targets matching the given criteria
STDERR: IF n > 0: ALT-1: <n> targets is/are misconfigured in all their build configurations:
STDERR: IF n > 0: ALT-2: <n> targets is/are misconfigured in some of their build configurations:
STDERR: 	- (ALT-2:<build_configuration>/)<target_name> build number differs in project conf and Info.plist (when bumping build number, the Info.plist version will be used, unless only --force-apple-versioning is set)
STDERR: 	- (ALT-2:<build_configuration>/)<target_name> Info.plist file not found or unreadable (path <path_to_plist>)
STDERR: 	IF --error-on-no-apple-versioning: - (ALT-2:<build_configuration>/)<target_name> is not configured to use apple-versioning (fix with bump-build-number or set-build-number --force-apple-versioning)
STDERR: 	IF --error-on-no-info-plist-version: - (ALT-2:<build_configuration>/)<target_name> have an Info.plist, but no build number in the plist (fix with bump-build-number or set-build-number --force-plist-versioning)
STDERR: 	IF --error-on-no-info-plist-version: - (ALT-2:<build_configuration>/)<target_name> does not have an Info.plist (you'll have to manually add an Info.plist file to fix this problem)
STDOUT: ALT-a: All targets and configurations are setup with build number <targets_build_number>
STDOUT: ALT-b: Build numbers by targets:
STDOUT: ALT-c: Build numbers by targets and configurations:
STDOUT:	ALT-bc: - (ALT-c: <build_configuration>/)<target_name>: <build_number>

print-build-number --porcelain
------------------------------
STDOUT: <pbxproj path>
STDOUT: safe_target1,safe_target2,safe_target3,...
STDERR: cfg_err:diff_build_number <safe_build_configuration>/<safe_target_name>
STDERR: err:unreadable_plist <safe_build_configuration>/<safe_target_name>/<safe_plist_path>
STDERR: IF --error-on-no-apple-versioning: cfg_err:no_apple_vers <safe_build_configuration>/<safe_target_name>
STDERR: IF --error-on-no-info-plist-version: cfg_err:no_plist_build_number <safe_build_configuration>/<safe_target_name>
STDERR: IF --error-on-no-info-plist-version: cfg_err:no_plist <safe_build_configuration>/<safe_target_name>
STDOUT: ((|<safe_build_configuration>)/<safe_target_name>):build_number
STDOUT: ...

bump-build-number [--porcelain]
-------------------------------
Outputs pbxproj, matching targets and relevant misconfigurations the same way print-build-number does before bumping
Bumps
Outputs new build number, the same way print-build-number does (last lines of print-build-number)

set-build-number [--porcelain]
------------------------------
Outputs pbxproj, matching targets and relevant misconfigurations the same way print-build-number does before setting build number
Sets build number
Outputs new build number, the same way print-build-number does (last lines of print-build-number)

print-marketing-version
-----------------------
STDOUT: Using pbxproj file <pbxproj path>
STDOUT: Found <n> targets matching the given criteria
STDERR: IF n > 0: ALT-1: <n> targets is/are misconfigured in all their build configurations:
STDERR: IF n > 0: ALT-2: <n> targets is/are misconfigured in some of their build configurations:
STDERR: 	- (ALT-2:<build_configuration>/)<target_name> does not have an Info.plist
STDERR: 	- (ALT-2:<build_configuration>/)<target_name> Info.plist file not found or unreadable (path <path_to_plist>)
STDERR: 	- (ALT-2:<build_configuration>/)<target_name> have an Info.plist, no marketing version in the plist (fix with set-marketing-version)
STDOUT: ALT-a: All targets and configurations are setup with marketing version <targets_marketing_version>
STDOUT: ALT-b: Marketing versions by targets
STDOUT: ALT-c: Marketing versions by targets and configurations:
STDOUT:	ALT-bc: - (ALT-c: <build_configuration>/)<target_name>: <marketing_version>

print-marketing-version --porcelain
-----------------------------------
STDOUT: <pbxproj path>
STDOUT: safe_target1,safe_target2,safe_target3,...
STDERR: cfg_err:no_plist <safe_build_configuration>/<safe_target_name>
STDERR: err:unreadable_plist <safe_build_configuration>/<safe_target_name>/<safe_plist_path>
STDERR: cfg_err:no_plist_marketing_version <safe_build_configuration>/<safe_target_name>
STDOUT: ((|<safe_build_configuration>)/<safe_target_name>):marketing_version
STDOUT: ...

set-marketing-version
---------------------
Outputs pbxproj, matching targets and relevant misconfigurations the same way print-marketing-version does before setting marketing version
Sets marketing version
Outputs new marketing version, the same way print-marketing-version does (last lines of print-marketing-version)

print-swift-code
----------------
Outputs pbxproj, matching targets and relevant misconfigurations the same way print-build-number does
STDOUT: ALT-a: Marketing versions by targets
STDOUT: ALT-b: Marketing versions by targets and configurations:
STDOUT:	- (ALT-b: <build_configuration>/)<target_name>:
STDOUT:		<swift_code (follows indentation)>

print-swift-code --porcelain
----------------------------
STDOUT: <pbxproj path>
STDOUT: safe_target1,safe_target2,safe_target3,...
Same errors as print-build-number --porcelain
STDOUT: (|<safe_build_configuration>)/<safe_target_name>
STDOUT: --- START SWIFT IMPLEMENTATION ---
STDOUT: Swift implementation
STDOUT: --- END SWIFT IMPLEMENTATION ---
STDOUT: ...
*/

func usage<TargetStream: TextOutputStream>(program_name: String, stream: inout TargetStream) {
	print("hagvtool - happn agvtool", to: &stream)
	print("The goal of the project is to provide agvtool with support for targets in a project. The CVS part of agvtool has been completly dropped.", to: &stream)
	print("", to: &stream)
	print("Usage: \(program_name) [--project-path=xcodeproj_path] [--targets=target_name_1,target_name_2,...] command [command_args]", to: &stream)
	print("When a target name is given, regular expression are supported.", to: &stream)
	print("", to: &stream)
	print("Commands are:", to: &stream)
	print("   help", to: &stream)
	print("      Outputs this help", to: &stream)
	print("", to: &stream)
	print("   print-build-number | what-version | vers [--error-on-no-apple-versioning] [--error-on-no-plist-version] [--porcelain]", to: &stream)
	print("      Outputs the build numbers of the given targets, or all the targets if none are specified", to: &stream)
	print("", to: &stream)
	print("   bump-build-number | next-version | bump [--force-apple-versioning] [--force-plist-versioning] [--porcelain|--quiet]", to: &stream)
	print("      Bump the build numbers of the given targets, or all the targets if none are specified and outputs the new build numbers", to: &stream)
	print("", to: &stream)
	print("   set-build-number | new-version [--force-apple-versioning] [--force-plist-versioning] [--porcelain|--quiet] new_build_number", to: &stream)
	print("      Set the build numbers of the given targets, or all the targets if none are specified and outputs the new build numbers", to: &stream)
	print("", to: &stream)
	print("   print-marketing-version | what-marketing-version | mvers [--porcelain]", to: &stream)
	print("      Outputs the marketing versions of the given targets, or all the targets if none are specified", to: &stream)
	print("", to: &stream)
	print("   set-marketing-version | new-marketing-version [--porcelain|--quiet] new_marketing_version", to: &stream)
	print("      Set the marketing versions of the given targets, or all the targets if none are specified and outputs the new marketing numbers", to: &stream)
	print("", to: &stream)
	print("   print-swift-code [--porcelain]", to: &stream)
	print("      Outputs the Swift code you’ll have to use in order to access the version of the given targets in a Swift project", to: &stream)
}

/* Returns the arg at the given index, or prints "Syntax error: error_message"
 * and the usage, then exits with syntax error if there is not enough arguments
 * given to the program */
func argAtIndexOrExit(_ i: Int, error_message: String) -> String {
	guard CommandLine.arguments.count > i else {
		print("Syntax error: \(error_message)", to: &mx_stderr)
		usage(program_name: CommandLine.arguments[0], stream: &mx_stderr)
		exit(1)
	}
	
	return CommandLine.arguments[i]
}

/* Takes the current arg position in input and a dictionary of long args names
 * with the corresponding action to execute when the long arg is found.
 * Returns the new arg position when all long args have been found. */
func getLongArgs(argIdx: Int, longArgs: [String: (String) -> Void]) -> Int {
	var i = argIdx
	
	func stringByDeletingPrefixIfPresent(_ prefix: String, from string: String) -> String? {
		if string.hasPrefix(prefix) {
			return string[string.index(string.startIndex, offsetBy: prefix.characters.count)..<string.endIndex]
		}
		
		return nil
	}
	
	
	longArgLoop: while true {
		let arg = argAtIndexOrExit(i, error_message: "Syntax error"); i += 1
		
		for (longArg, action) in longArgs {
			if let no_prefix = stringByDeletingPrefixIfPresent("--\(longArg)=", from: arg) {
				action(no_prefix)
				continue longArgLoop
			}
		}
		
		if arg != "--" {i -= 1}
		break
	}
	
	return i
}


/* ***************
   MARK: - Objects
   *************** */

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
	
	let name: String
	
	let infoPlistPath: String?
	let infoPlistFormat: PropertyListSerialization.PropertyListFormat? /* nil if plist is unreadable */
	
	let infoPlistBuildNumber: String?
	let infoPlistMarketingVersion: String?
	
	let versioningSystem: VersioningSystem
	let buildNumber: String?
	
	let versioningSourceFilename: String
	let versioningPrefix: String
	let versioningSuffix: String
	
	let versioningUsername: String? /* What's the use? */
	let versioningExportDeclaration: String? /* Unused in our case. */
	
}

struct Target {
	
	let name: String
	let buildConfigs: [BuildConfig]
	
}

/* ***********************************
   MARK: - Retrieving Matching Targets
   *********************************** */

var curArgIdx = 1

var project_path_arg: String?
var targets_criteria_arg: String?
curArgIdx = getLongArgs(argIdx: curArgIdx, longArgs: [
		"project-path": { project_path_arg = $0 },
		"targets": { targets_criteria_arg = $0 }
	]
)

let targets_criteria: [NSRegularExpression]?
if let targets_criteria_arg = targets_criteria_arg {
	var criteriaBuilding = [NSRegularExpression]()
	for targets_criterion_arg in targets_criteria_arg.components(separatedBy: ",") {
		if let criterion = try? NSRegularExpression(pattern: targets_criterion_arg, options: []) {
			criteriaBuilding.append(criterion)
		} else {
			print("Cannot parse criterion \"\(targets_criterion_arg)\" for target matching as a regexp. Faulting back to a non-regular expression matching.", to: &mx_stderr)
			if let criterion = try? NSRegularExpression(pattern: targets_criterion_arg, options: .ignoreMetacharacters) {
				criteriaBuilding.append(criterion)
			} else {
				print("   Actually, even that fails for some reasons... dropping this criterion!", to: &mx_stderr)
			}
		}
	}
	targets_criteria = criteriaBuilding
} else {
	targets_criteria = nil
}

let project_path: String
if let p = project_path_arg {project_path = p}
else {
	/* Let's find the project */
	guard let paths = try? FileManager.default.contentsOfDirectory(atPath: ".") else {
		print("Cannot list files in cwd", to: &mx_stderr)
		exit(2)
	}
	let xcodeproj_paths = paths.filter {$0.hasSuffix("xcodeproj")}
	guard xcodeproj_paths.count == 1 else {
		print("No or more than one xcodeproj files found in cwd", to: &mx_stderr)
		exit(2)
	}
	project_path = xcodeproj_paths[0]
}

let project_url = URL(fileURLWithPath: project_path, isDirectory: true)
let pbxproj_url = URL(fileURLWithPath: "project.pbxproj", isDirectory: false, relativeTo: project_url)

/* Checking the pbxproj file exists */
var isDir: ObjCBool = true
guard FileManager.default.fileExists(atPath: pbxproj_url.path, isDirectory: &isDir) && !isDir.boolValue else {
	print("project.pbxproj does not exist or is a directory", to: &mx_stderr)
	exit(2)
}

/* Reading pbxproj file */
guard let pbxproj_data = try? Data(contentsOf: pbxproj_url) else {
	print("Cannot read contents of pbxproj file (\(pbxproj_url))", to: &mx_stderr)
	exit(2)
}

/* Deserializing the pbxproj */
//var format = PropertyListSerialization.PropertyListFormat.xml
guard let pbxproj_unarchived = (try? PropertyListSerialization.propertyList(from: pbxproj_data, options: [], format: nil/*&format*/)) as? [String: Any], let pbxproj_objects = pbxproj_unarchived["objects"] as? [String: Any] else {
	print("Cannot deserialize contents of pbxproj file (\(pbxproj_url))", to: &mx_stderr)
	exit(2)
}
/* Now, "format" is (should be) PropertyListSerialization.PropertyListFormat.openStep */

/* Resolving root object from pbxproj */
guard let pbxproj_object_ref = pbxproj_unarchived["rootObject"] as? String, let pbxproj_object = pbxproj_objects[pbxproj_object_ref] as? [String: Any], pbxproj_object["isa"] as? String == "PBXProject" else {
	print("Unexpected content of pbxproj file (\(pbxproj_url)): rootObject is undefined, or corresponding object does not exist, or is not (isa) a PBXProject", to: &mx_stderr)
	exit(2)
}

/* We can now compute the project "dir" path, which is the root from which Xcode will fetch relative path (seems to be at least) */
let project_dir_path = URL(fileURLWithPath: pbxproj_object["projectDirPath"] as? String ?? "", isDirectory: true, relativeTo: URL(fileURLWithPath: "..", isDirectory: true, relativeTo: project_url))

/* To retrieve the targets, we first get the refs of the project's targets */
guard let target_refs = pbxproj_object["targets"] as? [String] else {
	print("Cannot list targets of project from pbxproj file (\(pbxproj_url))", to: &mx_stderr)
	exit(2)
}

var targets = [Target]()
for target_ref in target_refs {
	/* Let's fetch the object for the current target ref */
	guard let target_object = pbxproj_objects[target_ref] as? [String: Any] else {
		print("Cannot get target object for ref \(target_ref) from pbxproj file (\(pbxproj_url))", to: &mx_stderr)
		exit(2)
	}
	/* Only native targets are considered */
	guard target_object["isa"] as? String == "PBXNativeTarget" else {continue}
	
	/* Retrieving the name of the target */
	guard let target_name = target_object["name"] as? String else {
		print("Cannot get target name from target ref \(target_ref) from pbxproj file (\(pbxproj_url))", to: &mx_stderr)
		exit(2)
	}
	/* Let's match the target's name to the criteria given by the user */
	if let targets_criteria = targets_criteria {
		var match = false
		let target_name_range = NSRange(location: 0, length: (target_name as NSString).length)
		for targets_criterion in targets_criteria {
			targets_criterion.enumerateMatches(in: target_name, options: [.anchored], range: target_name_range) { result, flags, stop in
				guard let result = result else {return}
				if result.range.location == target_name_range.location && result.range.length == target_name_range.length {
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
	guard let build_configuration_list_ref = target_object["buildConfigurationList"] as? String else {
		print("Cannot get build configuration list ref for target ref \(target_ref) from pbxproj file (\(pbxproj_url))", to: &mx_stderr)
		exit(2)
	}
	/* Let's get the actual configuration list from its ref, and check we actually get a (isa) "XCConfigurationList" object */
	guard let build_configuration_list_object = pbxproj_objects[build_configuration_list_ref] as? [String: Any], build_configuration_list_object["isa"] as? String == "XCConfigurationList" else {
		print("Cannot get build configuration list object from ref \(build_configuration_list_ref) for target ref \(target_ref) from pbxproj file (\(pbxproj_url))", to: &mx_stderr)
		exit(2)
	}
	/* We can now retrieve the configurations ref from the list object */
	guard let build_configuration_refs = build_configuration_list_object["buildConfigurations"] as? [String] else {
		print("Cannot get build configuration refs from build configuration list from ref \(build_configuration_list_ref) for target ref \(target_ref) from pbxproj file (\(pbxproj_url))", to: &mx_stderr)
		exit(2)
	}
	var build_configurations = [BuildConfig]()
	for build_configuration_ref in build_configuration_refs {
		/* We retrieve the actual configuration object (and check it's actually a (isa) "XCBuildConfiguration") */
		guard let build_configuration_object = pbxproj_objects[build_configuration_ref] as? [String: Any], build_configuration_object["isa"] as? String == "XCBuildConfiguration" else {
			print("Cannot get build configuration object from ref \(build_configuration_ref) from build configuration list from ref \(build_configuration_list_ref) for target ref \(target_ref) from pbxproj file (\(pbxproj_url))", to: &mx_stderr)
			exit(2)
		}
		/* We need the name of the configuration */
		guard let build_configuration_name = build_configuration_object["name"] as? String else {
			print("Cannot get build configuration name from build configuration object from ref \(build_configuration_ref) from build configuration list from ref \(build_configuration_list_ref) for target ref \(target_ref) from pbxproj file (\(pbxproj_url))", to: &mx_stderr)
			exit(2)
		}
		/* The build settings of the configuration will give us all the versioning info we need. Note, as said at the
		 * beginning of the project, we don't actually resolve the build settings. Only the "direct" settings of the
		 * target are considered. If a project has some versioning information configured at the project level, or in
		 * configuration files, they will be ignored. */
		guard let build_settings = build_configuration_object["buildSettings"]  as? [String: Any] else {
			print("Cannot get build settings from build configuration object from ref \(build_configuration_ref) from build configuration list from ref \(build_configuration_list_ref) for target ref \(target_ref) from pbxproj file (\(pbxproj_url))", to: &mx_stderr)
			exit(2)
		}
		let versioning_system = BuildConfig.VersioningSystem(fromBuildSetting: build_settings["VERSIONING_SYSTEM"] as? String)
		let build_number = build_settings["CURRENT_PROJECT_VERSION"] as? String
		let versioning_source_filename = build_settings["VERSION_INFO_FILE"] as? String
		let versioning_prefix = build_settings["VERSION_INFO_PREFIX"] as? String
		let versioning_suffix = build_settings["VERSION_INFO_SUFFIX"] as? String
		let versioning_username = build_settings["VERSION_INFO_BUILDER"] as? String
		let versioning_export_declaration = build_settings["VERSION_INFO_EXPORT_DECL"] as? String
		let info_plist_path = build_settings["INFOPLIST_FILE"] as? String
		let info_plist_marketing_version: String?
		let info_plist_build_number: String?
		let info_plist_format: PropertyListSerialization.PropertyListFormat?
		
		do {
			/* Now to parse the Info.plist file! */
			guard let info_plist_path = info_plist_path else {throw NSError()}
			
			let plist_url = URL(fileURLWithPath: info_plist_path, isDirectory: false, relativeTo: project_dir_path)
			guard let stream = InputStream(url: plist_url) else {throw NSError()}
			stream.open(); defer {stream.close()}
			
			var format = PropertyListSerialization.PropertyListFormat.xml
			guard let plist_unarchived = try PropertyListSerialization.propertyList(with: stream, options: [], format: &format) as? [String: Any] else {throw NSError()}
			
			info_plist_format = format
			info_plist_build_number = plist_unarchived["CFBundleVersion"] as? String
			info_plist_marketing_version = plist_unarchived["CFBundleShortVersionString"] as? String
		} catch {
			info_plist_marketing_version = nil
			info_plist_build_number = nil
			info_plist_format = nil
		}
		let build_config = BuildConfig(
			name: build_configuration_name,
			infoPlistPath: info_plist_path,
			infoPlistFormat: info_plist_format,
			infoPlistBuildNumber: info_plist_build_number,
			infoPlistMarketingVersion: info_plist_marketing_version,
			versioningSystem: versioning_system,
			buildNumber: build_number,
			versioningSourceFilename: versioning_source_filename ?? target_name + "_vers.c",
			versioningPrefix: versioning_prefix ?? "",
			versioningSuffix: versioning_suffix ?? "",
			versioningUsername: versioning_username,
			versioningExportDeclaration: versioning_export_declaration
		)
		build_configurations.append(build_config)
	}
	let target = Target(name: target_name, buildConfigs: build_configurations)
	targets.append(target)
}


/* ************************
   MARK: - Applying Command
   ************************ */

curArgIdx += 1
switch argAtIndexOrExit(curArgIdx-1, error_message: "Command is required") {
case "help":
	usage(program_name: CommandLine.arguments[0], stream: &mx_stdout)
	
case "print-build-number", "what-version", "vers":
	()
	
case "bump-build-number", "next-version", "bump":
	()
	
case "set-build-number", "new-version":
	()
	
case "print-marketing-version", "what-marketing-version", "mvers":
	()
	
case "set-marketing-version", "new-marketing-version":
	()
	
case "print-swift-code":
	()
	
default:
	print("Unknown command \(CommandLine.arguments[1])", to: &mx_stderr)
	usage(program_name: CommandLine.arguments[0], stream: &mx_stderr)
	exit(2)
}
