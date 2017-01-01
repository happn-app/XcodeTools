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
STDOUT: Using pbxproj file at <pbxproj path>
STDOUT: Found <n> target(s) matching the given criteria
STDERR: IF n > 0: ALT-1: <n> targets is/are misconfigured in all of their build configurations:
STDERR: IF n > 0: ALT-2: <n> targets is/are misconfigured in some of their build configurations:
STDERR: 	- "<target_name>(ON AMBIGUITY:/<build_configuration>)" build numbers differ in project conf and Info.plist (when bumping build number, the Info.plist version will be used, unless only --force-apple-versioning is set)
STDERR: 	- "<target_name>(ON AMBIGUITY:/<build_configuration>)" Info.plist file not found or unreadable (path <path_to_plist>)
STDERR: 	IF --error-on-no-apple-versioning: - "<target_name>(ON AMBIGUITY:/<build_configuration>)" is not configured to use apple-versioning, or version in project conf is empty (fix with bump-build-number or set-build-number --force-apple-versioning)
STDERR: 	IF --error-on-no-plist-version: - "<target_name>(ON AMBIGUITY:/<build_configuration>)" have an Info.plist, but no build number in the plist (fix with bump-build-number or set-build-number --force-plist-versioning)
STDERR: 	IF --error-on-no-plist-version: - "<target_name>(ON AMBIGUITY:/<build_configuration>)" does not have an Info.plist (you'll have to manually add an Info.plist file to fix this problem)
STDOUT: ALT-a: All targets and configurations are setup with build number <targets_build_number>
STDOUT: ALT-b: Build numbers by targets:
STDOUT: ALT-c: Build numbers by targets and configurations:
STDOUT:	ALT-bc: - <target_name>(ALT-c: /<build_configuration>): <build_number>

print-build-number --porcelain
------------------------------
STDOUT: <pbxproj path>
STDOUT: safe_target1,safe_target2,safe_target3,...
STDERR: cfg_err:diff_build_number <safe_target_name>/<safe_build_configuration>
STDERR: err:unreadable_plist <safe_target_name>/<safe_build_configuration>/<safe_plist_path>
STDERR: IF --error-on-no-apple-versioning: cfg_err:no_apple_version <safe_target_name>/<safe_build_configuration>
STDERR: IF --error-on-no-info-plist-version: cfg_err:no_plist_build_number <safe_target_name>/<safe_build_configuration>
STDERR: IF --error-on-no-info-plist-version: cfg_err:no_plist <safe_target_name>/<safe_build_configuration>
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
STDOUT: Using pbxproj file at <pbxproj path>
STDOUT: Found <n> target(s) matching the given criteria
STDERR: IF n > 0: ALT-1: <n> targets is/are misconfigured in all of their build configurations:
STDERR: IF n > 0: ALT-2: <n> targets is/are misconfigured in some of their build configurations:
STDERR: 	- "<target_name>(ON AMBIGUITY:/<build_configuration>)" does not have an Info.plist
STDERR: 	- "<target_name>(ON AMBIGUITY:/<build_configuration>)" Info.plist file not found or unreadable (path <path_to_plist>)
STDERR: 	- "<target_name>(ON AMBIGUITY:/<build_configuration>)" have an Info.plist, but no marketing version in the plist (fix with set-marketing-version)
STDOUT: ALT-a: All targets and configurations are setup with marketing version <targets_marketing_version>
STDOUT: ALT-b: Marketing versions by targets
STDOUT: ALT-c: Marketing versions by targets and configurations:
STDOUT:	ALT-bc: - <target_name>(ALT-c: /<build_configuration>): <marketing_version>

print-marketing-version --porcelain
-----------------------------------
STDOUT: <pbxproj path>
STDOUT: safe_target1,safe_target2,safe_target3,...
STDERR: cfg_err:no_plist <safe_target_name>/<safe_build_configuration>
STDERR: err:unreadable_plist <safe_target_name>/<safe_build_configuration>/<safe_plist_path>
STDERR: cfg_err:no_plist_marketing_version <safe_target_name>/<safe_build_configuration>
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
STDOUT: ALT-a: Marketing versions by targets:
STDOUT: ALT-b: Marketing versions by targets and configurations:
STDOUT:	- "<target_name>(ALT-b: /<build_configuration>)":
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
	print("Usage: \(program_name) [--project-path=xcodeproj_path] [--targets=target_name_1,target_name_2,...] [--porcelain|--quiet] command [command_args]", to: &stream)
	print("When a target name is given, regular expression are supported.", to: &stream)
	print("", to: &stream)
	print("Commands are:", to: &stream)
	print("   print-build-number | what-version | vers [--error-on-no-apple-versioning] [--error-on-no-plist-version] ", to: &stream)
	print("      Outputs the build numbers of the given targets, or all the targets if none are specified", to: &stream)
	print("", to: &stream)
	print("   bump-build-number | next-version | bump [--force-apple-versioning] [--force-plist-versioning]", to: &stream)
	print("      Bump the build numbers of the given targets, or all the targets if none are specified and outputs the new build numbers", to: &stream)
	print("", to: &stream)
	print("   set-build-number | new-version [--force-apple-versioning] [--force-plist-versioning] new_build_number", to: &stream)
	print("      Set the build numbers of the given targets, or all the targets if none are specified and outputs the new build numbers", to: &stream)
	print("", to: &stream)
	print("   print-marketing-version | what-marketing-version | mvers", to: &stream)
	print("      Outputs the marketing versions of the given targets, or all the targets if none are specified", to: &stream)
	print("", to: &stream)
	print("   set-marketing-version | new-marketing-version new_marketing_version", to: &stream)
	print("      Set the marketing versions of the given targets, or all the targets if none are specified and outputs the new marketing numbers", to: &stream)
	print("", to: &stream)
	print("   print-swift-code", to: &stream)
	print("      Outputs the Swift code you’ll have to use in order to access the version of the given targets in a Swift project", to: &stream)
}

/* Returns the arg at the given index, or prints "Syntax error: error_message"
 * and the usage, then exits with syntax error if there is not enough arguments
 * given to the program */
func argAtIndexOrExit(_ i: inout Int, error_message: String) -> String {
	guard CommandLine.arguments.count > i else {
		print("Syntax error: \(error_message)", to: &mx_stderr)
		usage(program_name: CommandLine.arguments[0], stream: &mx_stderr)
		exit(1)
	}
	
	i += 1
	return CommandLine.arguments[i-1]
}

func argAtIndex(_ i: inout Int) -> String? {
	guard CommandLine.arguments.count > i else {return nil}
	
	i += 1
	return CommandLine.arguments[i-1]
}

func getLongArgValue(fromGetLongArgsValue: String?, argIdx: inout Int) -> String {
	if let v = fromGetLongArgsValue {return v}
	return argAtIndexOrExit(&argIdx, error_message: "Cannot find value for long arg.")
}

/* Takes the current arg position in input and a dictionary of long args names
 * with the corresponding action to execute when the long arg is found.
 * Returns the new arg position when all long args have been found. */
func getLongArgs(argIdx: inout Int, longArgs: [String: (_ curArgPos: /* :( inout does not work here (Swift 3.0.1) */Int, _ argValue: String?) -> Int]) {
	func stringByDeletingPrefixIfPresent(_ prefix: String, from string: String) -> String? {
		if string.hasPrefix(prefix) {
			return string[string.index(string.startIndex, offsetBy: prefix.characters.count)..<string.endIndex]
		}
		
		return nil
	}
	
	
	longArgLoop: while true {
		guard let arg = argAtIndex(&argIdx) else {return}
		
		for (longArg, action) in longArgs {
			if let no_prefix = stringByDeletingPrefixIfPresent("--\(longArg)=", from: arg) {
				argIdx = action(argIdx, no_prefix)
				continue longArgLoop
			} else if "--" + longArg == arg {
				argIdx = action(argIdx, nil)
				continue longArgLoop
			}
		}
		
		if arg != "--" {argIdx -= 1}
		break
	}
}

/* ***********************************
   MARK: - Retrieving Matching Targets
   *********************************** */

var curArgIdx = 1

var project_path_arg: String?
var targets_criteria_arg: String?
var log_type = LogType.humanReadable
getLongArgs(argIdx: &curArgIdx, longArgs: [
		"project-path": { var i = $0; project_path_arg     = getLongArgValue(fromGetLongArgsValue: $1, argIdx: &i); return i },
		"targets":      { var i = $0; targets_criteria_arg = getLongArgValue(fromGetLongArgsValue: $1, argIdx: &i); return i },
		"porcelain": { log_type = .porcelain; return $0.0 },
		"quiet":     { log_type = .quiet;     return $0.0 }
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
let pbxproj_url = Target.pbxprojURLFromProject(url: project_url)

guard let targets = Target.targetsFromProject(url: project_url, targetsCriteria: targets_criteria) else {
	exit(2)
}

/* ***************************
   MARK: - Showing Common Info
   *************************** */

switch log_type {
case .quiet:
	()
	
case .porcelain:
	print("\(pbxproj_url.path)")
	
	var first = true
	for target in targets {
		if !first {print(",", terminator: "")}
		print(target.name.safeString(forChars: ","), terminator: "")
		first = false
	}
	print()
	
case .humanReadable:
	print("Using pbxproj file at \(pbxproj_url.path)")
	print("Found \(targets.count) target\(targets.count != 1 ? "s" : "") matching the given criteria")
	
case .json:
	fatalError("Not implemented")
}

/* ************************
   MARK: - Applying Command
   ************************ */

switch argAtIndexOrExit(&curArgIdx, error_message: "Command is required") {
case "print-build-number", "what-version", "vers":
	var errOnNoPlistVersion = false
	var errOnNoAppleVersioning = false
	getLongArgs(argIdx: &curArgIdx, longArgs: [
			"error-on-no-plist-version":    { errOnNoPlistVersion    = true; return $0.0 },
			"error-on-no-apple-versioning": { errOnNoAppleVersioning = true; return $0.0 }
		]
	)
	let misconfigsMask = BuildConfig.Misconfigs(
		noInfoPlist: errOnNoPlistVersion, unreadablePlistPath: "", noBuildNumberInPlist: errOnNoPlistVersion,
		noMarketingNumberInPlist: false,
		noAppleVersioning: errOnNoAppleVersioning,
		diffBuildNumbers: (projectConf: "", infoPlist: "")
	)
	
	/* Showing errors if any */
	guard !print_error(forTargets: targets, withMisconfigsMask: misconfigsMask, logType: log_type) else {
		exit(3)
	}
	
	/* Showing found build versions */
	print_build_versions(forTargets: targets, logType: log_type)
	
case "bump-build-number", "next-version", "bump":
	()
	
case "set-build-number", "new-version":
	()
	
case "print-marketing-version", "what-marketing-version", "mvers":
	let misconfigsMask = BuildConfig.Misconfigs(
		noInfoPlist: true, unreadablePlistPath: "",
		noBuildNumberInPlist: false, noMarketingNumberInPlist: true,
		noAppleVersioning: false, diffBuildNumbers: nil
	)
	
	/* Showing errors if any */
	guard !print_error(forTargets: targets, withMisconfigsMask: misconfigsMask, logType: log_type) else {
		exit(3)
	}
	
	/* Showing found build versions */
	print_marketing_versions(forTargets: targets, logType: log_type)
	
case "set-marketing-version", "new-marketing-version":
	()
	
case "print-swift-code":
	let misconfigsMask = BuildConfig.Misconfigs(
		noInfoPlist: false, unreadablePlistPath:  nil,
		noBuildNumberInPlist: false, noMarketingNumberInPlist: false,
		noAppleVersioning: true, diffBuildNumbers: nil
	)
	
	/* Showing errors if any, but not exiting in case of errors... */
	_ = print_error(forTargets: targets, withMisconfigsMask: misconfigsMask, logType: log_type)
	
	/*
	for target in targets {
		/* Uniquing on: productName, versioningSystem, versioningSourceFilename, versioningPrefix, versioningSuffix */
		for buildConfig in target.buildConfigs {
			print("/* Versioning filename is \"\(buildConfig.versioningSourceFilename)\" */")
			print("let hdl = dlopen(nil, 0)")
			print("defer {if let hdl = hdl {dlclose(hdl)}}")
			print("let versionNumberPtr = hdl.flatMap { dlsym($0, \"" + buildConfig.versioningPrefix + buildConfig.productName.replacingOccurrences(of: " ", with: "_") /* Probably more replacements to do */ + "VersionNumber" + buildConfig.versioningSuffix + "\") }")
			print("let versionStringPtr = hdl.flatMap { dlsym($0, \"" + buildConfig.versioningPrefix + buildConfig.productName.replacingOccurrences(of: " ", with: "_") /* Probably more replacements to do */ + "VersionString" + buildConfig.versioningSuffix + "\") }")
			print("let versionNumber = versionNumberPtr?.assumingMemoryBound(to: Double.self).pointee")
			print("let versionString = versionStringPtr.map { String(cString: $0.assumingMemoryBound(to: CChar.self)) }")
		}
	}*/
	
default:
	print("Unknown command \(CommandLine.arguments[1])", to: &mx_stderr)
	usage(program_name: CommandLine.arguments[0], stream: &mx_stderr)
	exit(2)
}
