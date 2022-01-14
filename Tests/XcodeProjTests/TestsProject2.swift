import Foundation
import XCTest

@testable import XcodeProj



final class TestsProject2 : XCTestCase {
	
	let xcodeprojURL = URL(fileURLWithPath: #file, isDirectory: false).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("TestsData").appendingPathComponent("project2").appendingPathComponent("project2.xcodeproj")
	
	func testIterateFiles() throws {
		struct File : Hashable {
			var relativePath: String
			var type: String?
			init(relativePath: String, type: String?) {
				self.relativePath = relativePath
				self.type = type
			}
			init(url: URL, type: String?) {
				self.relativePath = url.relativePath
				self.type = type
			}
		}
		var res = Set<File>()
		let xcodeproj = try XcodeProj(xcodeprojURL: xcodeprojURL)
		try xcodeproj.iterateReferencedFiles{ url, fileType in
			XCTAssertTrue(res.insert(File(url: url, type: fileType)).inserted)
		}
		let ref = Set(
			arrayLiteral:
				File(relativePath: "project2/AppDelegate.swift",                                        type: "sourcecode.swift"),
				File(relativePath: "project2/ViewController.swift",                                     type: "sourcecode.swift"),
				File(relativePath: "project2/Assets.xcassets",                                          type: "folder.assetcatalog"),
				File(relativePath: "project2/Base.lproj/Main.storyboard",                               type: "file.storyboard"),
				File(relativePath: "project2/project2.entitlements",                                    type: "text.plist.entitlements"),
				File(relativePath: "Maybe SPM Packages in Folder",                                      type: "folder"),
				File(relativePath: "Maybe SPM Packages in Group/g-yes-full",                            type: "wrapper"),
				File(relativePath: "Maybe SPM Packages in Group/g-yes-no-product",                      type: "wrapper"),
				File(relativePath: "Maybe SPM Packages in Group/GAmazingLib2",                          type: "wrapper"),
				File(relativePath: "Maybe SPM Packages in Group/g-yes-broken-1",                        type: "wrapper"),
				File(relativePath: "Maybe SPM Packages in Group/g-yes-broken-2",                        type: "wrapper"),
				File(relativePath: "Maybe SPM Packages in Group/g-yes-broken-3",                        type: "wrapper"),
				File(relativePath: "Maybe SPM Packages in Group/g-yes-broken-4",                        type: "wrapper"),
				File(relativePath: "Maybe SPM Packages in Group/g-no-1",                                type: "folder"),
				File(relativePath: "Maybe SPM Packages in Group/g-no-2",                                type: "folder"),
				File(relativePath: "Maybe SPM Packages in Group/g-no-3",                                type: "folder"),
				File(relativePath: "SPM But As Group/g-yes-full/Package.swift",                         type: "sourcecode.swift"),
				File(relativePath: "SPM But As Group/g-yes-full/Sources/GAmazingLib/GAmazingLib.swift", type: "sourcecode.swift"),
				File(relativePath: "/tmp/__DUMMY_BUILT_PRODUCT_DIR__/project2.app",                     type: nil)
		)
		XCTAssertEqual(res, ref)
	}
	
	func testIteratePackages() throws {
		var res = Set<String>()
		let xcodeproj = try XcodeProj(xcodeprojURL: xcodeprojURL)
		try xcodeproj.iterateSPMPackagesInReferencedFile{ proj in
			XCTAssertTrue(res.insert(proj.rootURL.relativePath).inserted)
		}
		/* For now SPMProj does not check if package is actually valid, so we put them all. */
		let ref = Set(
			arrayLiteral:
				"Maybe SPM Packages in Group/g-yes-full",
				"Maybe SPM Packages in Group/g-yes-no-product",
				"Maybe SPM Packages in Group/GAmazingLib2",
				"Maybe SPM Packages in Group/g-yes-broken-1",
				"Maybe SPM Packages in Group/g-yes-broken-2",
				"Maybe SPM Packages in Group/g-yes-broken-3",
				"Maybe SPM Packages in Group/g-yes-broken-4"
		)
		XCTAssertEqual(res, ref)
	}
	
}
