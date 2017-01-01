/*
 * ErrorPrinter.swift
 * hagvtool
 *
 * Created by François Lamboley on 1/1/17.
 * Copyright © 2017 happn. All rights reserved.
 */

import Foundation



/** - Returns: `true` if errors had to be printed */
func print_error(forTargets targets: [Target], withMisconfigsMask misconfigsMask: BuildConfig.Misconfigs, logType: LogType) -> Bool {
	let n = targets.reduce(0) { $0 + ($1.distinctActualMisconfigurations(matchingMisconfigsMask: misconfigsMask).isEmpty ? 0 : 1) }
	let a = targets.reduce(true) { $0 && $1.doAllOrNoneOfBuildConfigsHaveMisconfigsMask(misconfigsMask) }
	if n > 0 {
		if .humanReadable ~= logType {
			print("\(n) target\(n != 1 ? "s are" : " is") misconfigured in \(a ? "all" : "some") of \(n != 1 ? "their" : "its") build configurations:", to: &mx_stderr)
		}
		let buildNumbersDifferMask = BuildConfig.Misconfigs(noInfoPlist: false, unreadablePlistPath: nil, noBuildNumberInPlist: false, noMarketingNumberInPlist: false, noAppleVersioning: false, diffBuildNumbers: (projectConf: "", infoPlist: ""))
		let unreadablePlistMask = BuildConfig.Misconfigs(noInfoPlist: false, unreadablePlistPath: "", noBuildNumberInPlist: false, noMarketingNumberInPlist: false, noAppleVersioning: false, diffBuildNumbers: nil)
		let noMarketingNumberInPlistMask = BuildConfig.Misconfigs(noInfoPlist: false, unreadablePlistPath: nil, noBuildNumberInPlist: false, noMarketingNumberInPlist: true, noAppleVersioning: false, diffBuildNumbers: nil)
		let noAppleVersioningMask = BuildConfig.Misconfigs(noInfoPlist: false, unreadablePlistPath: nil, noBuildNumberInPlist: false, noMarketingNumberInPlist: false, noAppleVersioning: true, diffBuildNumbers: nil)
		let noPlistVersionMask = BuildConfig.Misconfigs(noInfoPlist: false, unreadablePlistPath: nil, noBuildNumberInPlist: true, noMarketingNumberInPlist: false, noAppleVersioning: false, diffBuildNumbers: nil)
		let noPlistMask = BuildConfig.Misconfigs(noInfoPlist: true, unreadablePlistPath: nil, noBuildNumberInPlist: false, noMarketingNumberInPlist: false, noAppleVersioning: false, diffBuildNumbers: nil)
		for target in targets {
			if misconfigsMask.diffBuildNumbers != nil {
				/* Showing build numbers differ error */
				let buildConfigs = target.misconfiguredBuildConfigs(matchingMisconfigsMask: buildNumbersDifferMask)
				let showAll = (.porcelain ~= logType || .json ~= logType) || buildConfigs.count != target.buildConfigs.count
				for buildConfig in (showAll ? buildConfigs : [buildConfigs[0]]) {
					switch logType {
					case .quiet: (/*nop*/)
					case .porcelain:     print("cfg_err:diff_build_number \(target.name.safeString(forChars: "/"))/\(buildConfig.name.safeString(forChars: "/"))", to: &mx_stderr)
					case .humanReadable: print("   - \"\(target.name)\(showAll ? "/" + buildConfig.name : "")\" build numbers differ in project conf and Info.plist (when bumping build number, the Info.plist version will be used, unless only --force-apple-versioning is set)", to: &mx_stderr)
					case .json: fatalError("Not implemented")
					}
				}
			}
			if misconfigsMask.unreadablePlistPath != nil {
				/* Showing unreadable Info.plist error */
				let buildConfigs = target.misconfiguredBuildConfigs(matchingMisconfigsMask: unreadablePlistMask)
				let showAll = (.porcelain ~= logType || .json ~= logType) || buildConfigs.count != target.buildConfigs.count
				for buildConfig in (showAll ? buildConfigs : [buildConfigs[0]]) {
					switch logType {
					case .quiet: (/*nop*/)
					case .porcelain:     print("err:unreadable_plist \(target.name.safeString(forChars: "/"))/\(buildConfig.name.safeString(forChars: "/"))/\(buildConfig.misconfigs.unreadablePlistPath!.safeString(forChars: "/"))", to: &mx_stderr)
					case .humanReadable: print("   - \"\(target.name)\(showAll ? "/" + buildConfig.name : "")\" Info.plist file not found or unreadable (path \(buildConfig.misconfigs.unreadablePlistPath!))", to: &mx_stderr)
					case .json: fatalError("Not implemented")
					}
				}
			}
			if misconfigsMask.noAppleVersioning {
				/* Showing target not configured for Apple Versioning error */
				let buildConfigs = target.misconfiguredBuildConfigs(matchingMisconfigsMask: noAppleVersioningMask)
				let showAll = (.porcelain ~= logType || .json ~= logType) || buildConfigs.count != target.buildConfigs.count
				for buildConfig in (showAll ? buildConfigs : [buildConfigs[0]]) {
					switch logType {
					case .quiet: (/*nop*/)
					case .porcelain:     print("cfg_err:no_apple_version \(target.name.safeString(forChars: "/"))/\(buildConfig.name.safeString(forChars: "/"))", to: &mx_stderr)
					case .humanReadable: print("   - \"\(target.name)\(showAll ? "/" + buildConfig.name : "")\" is not configured to use apple-versioning, or version in project conf is empty (fix with bump-build-number or set-build-number --force-apple-versioning)", to: &mx_stderr)
					case .json: fatalError("Not implemented")
					}
				}
			}
			if misconfigsMask.noBuildNumberInPlist {
				/* Showing no build number in plist error */
				let buildConfigs = target.misconfiguredBuildConfigs(matchingMisconfigsMask: noPlistVersionMask)
				let showAll = (.porcelain ~= logType || .json ~= logType) || buildConfigs.count != target.buildConfigs.count
				for buildConfig in (showAll ? buildConfigs : [buildConfigs[0]]) {
					switch logType {
					case .quiet: (/*nop*/)
					case .porcelain:     print("cfg_err:no_plist_build_number \(target.name.safeString(forChars: "/"))/\(buildConfig.name.safeString(forChars: "/"))", to: &mx_stderr)
					case .humanReadable: print("   - \"\(target.name)\(showAll ? "/" + buildConfig.name : "")\" have an Info.plist, but no build number in the plist (fix with bump-build-number or set-build-number --force-plist-versioning)", to: &mx_stderr)
					case .json: fatalError("Not implemented")
					}
				}
			}
			if misconfigsMask.noMarketingNumberInPlist {
				/* Showing no marketing number in plist error */
				let buildConfigs = target.misconfiguredBuildConfigs(matchingMisconfigsMask: noMarketingNumberInPlistMask)
				let showAll = (.porcelain ~= logType || .json ~= logType) || buildConfigs.count != target.buildConfigs.count
				for buildConfig in (showAll ? buildConfigs : [buildConfigs[0]]) {
					switch logType {
					case .quiet: (/*nop*/)
					case .porcelain:     print("cfg_err:no_plist_marketing_version \(target.name.safeString(forChars: "/"))/\(buildConfig.name.safeString(forChars: "/"))", to: &mx_stderr)
					case .humanReadable: print("   - \"\(target.name)\(showAll ? "/" + buildConfig.name : "")\" have an Info.plist, but no marketing version in the plist (fix with set-marketing-version)", to: &mx_stderr)
					case .json: fatalError("Not implemented")
					}
				}
			}
			if misconfigsMask.noInfoPlist {
				/* Showing no plist error */
				let buildConfigs = target.misconfiguredBuildConfigs(matchingMisconfigsMask: noPlistMask)
				let showAll = (.porcelain ~= logType || .json ~= logType) || buildConfigs.count != target.buildConfigs.count
				for buildConfig in (showAll ? buildConfigs : [buildConfigs[0]]) {
					switch logType {
					case .quiet: (/*nop*/)
					case .porcelain:     print("cfg_err:no_plist \(target.name.safeString(forChars: "/"))/\(buildConfig.name.safeString(forChars: "/"))", to: &mx_stderr)
					case .humanReadable: print("   - \"\(target.name)\(showAll ? "/" + buildConfig.name : "")\" does not have an Info.plist (you'll have to manually add an Info.plist file to fix this problem)", to: &mx_stderr)
					case .json: fatalError("Not implemented")
					}
				}
			}
		}
		return true
	}
	return false
}

func print_build_versions(forTargets targets: [Target], logType: LogType) {
	var version: String?
	var diffVersions = false
	var diffVersionsInOneTarget = false
	for target in targets {
		let distinctVersions = target.distinctBuildNumbers
		
		if distinctVersions.count > 1 {
			diffVersionsInOneTarget = true
			diffVersions = true
			break
		}
		if let targetVersion = distinctVersions.first {
			if let version = version, version != targetVersion {
				diffVersions = true
			}
			version = targetVersion
		}
	}
	if !diffVersions {
		assert(!diffVersionsInOneTarget)
		if let version = version {
			switch logType {
			case .quiet: (/*nop*/)
			case .porcelain:     print(":\(version)")
			case .humanReadable: print("All targets and configurations are setup with build number \(version)")
			case .json: fatalError("Not implemented")
			}
		}
	} else {
		if .humanReadable ~= logType {
			print("Build numbers by targets\(diffVersionsInOneTarget ? " and configurations" : ""):")
		}
		for target in targets {
			let distinctVersions = target.distinctBuildNumbers
			if distinctVersions.count == 1 {
				if let v = distinctVersions[0] {
					switch logType {
					case .quiet: (/*nop*/)
					case .porcelain:     print("/\(target.name.safeString(forChars: ":")):\(v)")
					case .humanReadable: print("   - \(target.name): \(v)")
					case .json: fatalError("Not implemented")
					}
				}
			} else {
				for buildConfig in target.buildConfigs {
					if let v = buildConfig.fullBuildNumber.reduced() {
						switch logType {
						case .quiet: (/*nop*/)
						case .porcelain:     print("|\(buildConfig.name.safeString(forChars: "/"))/\(target.name.safeString(forChars: ":")):\(v)")
						case .humanReadable: print("   - \(target.name)/\(buildConfig.name): \(v)")
						case .json: fatalError("Not implemented")
						}
					}
				}
			}
		}
	}
}

func print_marketing_versions(forTargets targets: [Target], logType: LogType) {
	var version: String?
	var diffVersions = false
	var diffVersionsInOneTarget = false
	for target in targets {
		let distinctVersions = target.distinctMarketingVersions
		
		if distinctVersions.count > 1 {
			diffVersionsInOneTarget = true
			diffVersions = true
			break
		}
		if let targetVersion = distinctVersions.first {
			if let version = version, version != targetVersion {
				diffVersions = true
			}
			version = targetVersion
		}
	}
	if !diffVersions {
		assert(!diffVersionsInOneTarget)
		if let version = version {
			switch logType {
			case .quiet: (/*nop*/)
			case .porcelain:     print(":\(version)")
			case .humanReadable: print("All targets and configurations are setup with marketing version \(version)")
			case .json: fatalError("Not implemented")
			}
		}
	} else {
		if .humanReadable ~= logType {
			print("Marketing versions by targets\(diffVersionsInOneTarget ? " and configurations" : ""):")
		}
		for target in targets {
			let distinctVersions = target.distinctMarketingVersions
			if distinctVersions.count == 1 {
				if let v = distinctVersions[0] {
					switch logType {
					case .quiet: (/*nop*/)
					case .porcelain:     print("/\(target.name.safeString(forChars: ":")):\(v)")
					case .humanReadable: print("   - \(target.name): \(v)")
					case .json: fatalError("Not implemented")
					}
				}
			} else {
				for buildConfig in target.buildConfigs {
					if let v = buildConfig.infoPlistMarketingVersion {
						switch logType {
						case .quiet: (/*nop*/)
						case .porcelain:     print("|\(buildConfig.name.safeString(forChars: "/"))/\(target.name.safeString(forChars: ":")):\(v)")
						case .humanReadable: print("   - \(target.name)/\(buildConfig.name): \(v)")
						case .json: fatalError("Not implemented")
						}
					}
				}
			}
		}
	}
}
