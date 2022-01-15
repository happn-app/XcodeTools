import Foundation

import PackageGraph



public struct SPMTarget {
	
	public var name: String {
		resolvedTarget.name
	}
	
	public var sources: [URL] {
		resolvedTarget.sources.paths.map(\.asURL)
	}
	
	internal init(resolvedTarget: ResolvedTarget) {
		self.resolvedTarget = resolvedTarget
	}
	
	internal let resolvedTarget: ResolvedTarget
	
}
