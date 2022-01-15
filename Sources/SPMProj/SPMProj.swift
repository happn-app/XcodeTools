import Foundation

import Basics
import PackageGraph
import TSCBasic
import Workspace



public struct SPMProj {
	
	public let rootURL: URL
	public let projectManifestURL: URL
	
	public init(path: String? = nil) throws {
		try self.init(url: path.flatMap{ URL(fileURLWithPath: $0) })
	}
	
	public init(url: URL? = nil) throws {
		self.rootURL = url ?? URL(fileURLWithPath: ".")
		self.projectManifestURL = rootURL.appendingPathComponent("Package.swift")
		
		let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
		let workspace = try Workspace(forRootPackage: AbsolutePath(tempDir.path))
		
		let observability = ObservabilitySystem{ scope, diag in
			Conf.logger?.debug("Message from SPM: \(diag)")
		}
		
		self.packageGraph = try workspace.loadPackageGraph(rootPath: AbsolutePath(rootURL.path), observabilityScope: observability.topScope)
		guard packageGraph.rootPackages.count == 1 else {
			throw Err.cannotLoadPackage(rootURL)
		}
	}
	
	internal var packageGraph: PackageGraph
	internal var resolvedPackage: ResolvedPackage {
		packageGraph.rootPackages.first!
	}
	
}
