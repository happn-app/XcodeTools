/*
 * main.swift
 * hagvtool
 *
 * Created by François Lamboley on 12/13/16.
 * Copyright © 2016 happn. All rights reserved.
 */

import Foundation
import CoreFoundation



/* Outputs & Behaviours:

Note: FYI, the singular of criteria is criterion.

print-build-number
------------------
STDOUT: Using pbxproj file <pbxproj path>
STDOUT: Found <n> targets matching the given criteria
STDERR: IF n > 0: ALT-1: <n> targets is/are misconfigured in all their build configurations:
STDERR: IF n > 0: ALT-2: <n> targets is/are misconfigured in some of their build configurations:
STDERR: 	- (ALT-2:<build_configuration>/)<target_name> build number differs in project conf and Info.plist (when bumping build number, the Info.plist version will be used, unless only --force-apple-versioning is set)
STDERR: 	- (ALT-2:<build_configuration>/)<target_name> Info.plist file not found (path <path_to_plist)
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
STDERR: err:plist_not_found <safe_build_configuration>/<safe_target_name>/<safe_plist_path>
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
STDERR: 	- (ALT-2:<build_configuration>/)<target_name> Info.plist file not found (path <path_to_plist)
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
STDERR: err:plist_not_found <safe_build_configuration>/<safe_target_name>/<safe_plist_path>
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
	print("Usage: \(program_name) [--project_path=xcodeproj_path] command [command_args]", to: &stream)
	print("When a target name is given, regular expression are supported.", to: &stream)
	print("", to: &stream)
	print("Commands are:", to: &stream)
	print("   help", to: &stream)
	print("      Outputs this help", to: &stream)
	print("", to: &stream)
	print("   print-build-number | what-version | vers [--target=target_name_1,target_name_2,...] [--error-on-no-apple-versioning] [--error-on-no-plist-version] [--porcelain]", to: &stream)
	print("      Outputs the build numbers of the given targets, or all the targets if none are specified", to: &stream)
	print("", to: &stream)
	print("   bump-build-number | next-version | bump [--target=target_name ...] [--force-apple-versioning] [--force-plist-versioning] [--porcelain|--quiet]", to: &stream)
	print("      Bump the build numbers of the given targets, or all the targets if none are specified and outputs the new build numbers", to: &stream)
	print("", to: &stream)
	print("   set-build-number | new-version [--target=target_name ...] [--force-apple-versioning] [--force-plist-versioning] [--porcelain|--quiet] new_build_number", to: &stream)
	print("      Set the build numbers of the given targets, or all the targets if none are specified and outputs the new build numbers", to: &stream)
	print("", to: &stream)
	print("   print-marketing-version | what-marketing-version | mvers [--target=target_name ...] [--porcelain]", to: &stream)
	print("      Outputs the marketing versions of the given targets, or all the targets if none are specified", to: &stream)
	print("", to: &stream)
	print("   set-marketing-version | new-marketing-version [--target=target_name ...] [--porcelain|--quiet] new_marketing_version", to: &stream)
	print("      Set the marketing versions of the given targets, or all the targets if none are specified and outputs the new marketing numbers", to: &stream)
	print("", to: &stream)
	print("   print-swift-code [--target=target_name_1,target_name_2,...] [--porcelain]", to: &stream)
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

switch argAtIndexOrExit(1, error_message: "Command is required") {
case "help":
	usage(program_name: CommandLine.arguments[0], stream: &mx_stdout)
	
case "print-build-number", "what-version", "vers":
	let data = try! Data(contentsOf: URL(fileURLWithPath: "/Users/frizlab/Documents/Projects/happn/happn.xcodeproj/project.pbxproj"))
	//var format = PropertyListSerialization.PropertyListFormat.xml
	guard let archive = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil/*&format*/)) as? [String: Any], let objects = archive["objects"] as? [String: Any] else {exit(1)}
	/* format is PropertyListSerialization.PropertyListFormat.openStep here */
	guard let projectObjectRef = archive["rootObject"] as? String, let projectObject = objects[projectObjectRef] as? [String: Any], projectObject["isa"] as? String == "PBXProject" else {exit(1)}
	guard let targetRefs = projectObject["targets"] as? [String] else {exit(1)}
	for targetRef in targetRefs {
		guard let targetObject = objects[targetRef] as? [String: Any], let buildConfigurationListRef = targetObject["buildConfigurationList"] as? String else {exit(1)}
		guard targetObject["isa"] as? String == "PBXNativeTarget" else {continue}
		print(targetObject["name"] as? String)
		guard let buildConfigurationListObject = objects[buildConfigurationListRef] as? [String: Any], buildConfigurationListObject["isa"] as? String == "XCConfigurationList" else {exit(1)}
		guard let buildConfigurationRefs = buildConfigurationListObject["buildConfigurations"] as? [String] else {exit(1)}
		for buildConfigurationRef in buildConfigurationRefs {
			guard let buildConfigurationObject = objects[buildConfigurationRef] as? [String: Any], buildConfigurationObject["isa"] as? String == "XCBuildConfiguration" else {exit(1)}
			guard let buildSettings = buildConfigurationObject["buildSettings"] as? [String: Any], buildSettings["VERSIONING_SYSTEM"] as? String == "apple-generic" else {continue}
			print(buildSettings["INFOPLIST_FILE"] as? String)
			print(buildSettings["CURRENT_PROJECT_VERSION"] as? String)
		}
	}
	
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
