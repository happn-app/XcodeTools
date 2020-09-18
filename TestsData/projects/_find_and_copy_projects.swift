#!/usr/bin/swift sh

import Foundation

import SwiftShell // @kareman == master


/* swift-sh creates a binary whose path is not one we expect, so we cannot use
 * main.path directly.
 * Using the _ env variable is **extremely** hacky, but seems to do the job…
 * See https://github.com/mxcl/swift-sh/issues/101 */
let filepath = ProcessInfo.processInfo.environment["_"] ?? main.path

/* We go in the TestsData directory */
main.currentdirectory = URL(fileURLWithPath: filepath).deletingLastPathComponent().appendingPathComponent("..").path



do {
	guard main.arguments.count == 0 else {
		exit(errormessage: "usage: \(filepath)")
	}
	
	let output = run("mdfind", "-0", "-name", ".xcodeproj")
	if let e = output.error {throw e}
	
	let fm = FileManager.default
	for f in output.stdout.components(separatedBy: "\0") {
		guard !f.isEmpty else {continue}
		
		let url = URL(fileURLWithPath: f, isDirectory: true)
		guard !url.path.hasPrefix(main.currentdirectory) else {
			main.stdout.print("skipping project already in test folder: \(url.path)")
			continue
		}
		
		/* We assume project root is parent of xcodeproj. */
		let sourceRoot = url.deletingLastPathComponent()
		let name = sourceRoot.lastPathComponent
		let destinationRoot = URL(fileURLWithPath: "./projects", isDirectory: true).appendingPathComponent(name)
		
		guard !fm.fileExists(atPath: destinationRoot.path) else {
			main.stdout.print("skipping project already existing in test folder: \(url.path)")
			continue
		}
		
		main.stdout.print("copying files from \(sourceRoot.path) to \(destinationRoot.path)")
		guard let de = fm.enumerator(atPath: sourceRoot.path) else {
			main.stderror.print("cannot create directory enumerator, skipping path: \(url.path)")
			continue
		}
		
		while let f = de.nextObject() as! String? {
			guard !f.contains(".DS_Store") && !f.contains(".git/") && !f.contains(".build/") && !f.contains("xcuserdata/") && !f.contains("Carthage") else {
				continue
			}
			guard f.contains(".xcodeproj") || f.contains(".xcworkspace") || f.contains(".xcconfig") || f.contains(".plist") else {
				continue
			}
			let sourceFile = URL(fileURLWithPath: f, relativeTo: sourceRoot)
			let destinationFile = destinationRoot.appendingPathComponent(f)
			let destinationFolder = destinationRoot.appendingPathComponent(f).deletingLastPathComponent()
			do {
				try fm.createDirectory(atPath: destinationFolder.path, withIntermediateDirectories: true)
				
				var isDir = ObjCBool(true)
				if fm.fileExists(atPath: sourceFile.path, isDirectory: &isDir) && !isDir.boolValue {
					try fm.copyItem(at: sourceFile, to: destinationFile)
				}
			} catch {
				main.stderror.print("got error while processing file or folder, skipping (potentially partially processed) path: \(url.path)")
				main.stderror.print("error is \(error)")
				continue
			}
		}
	}
} catch {
	exit(error)
}
