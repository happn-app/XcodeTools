/*
 * utils.swift
 * hagvtool
 *
 * Created by François Lamboley on 12/15/16.
 * Copyright © 2016 happn. All rights reserved.
 */

import Foundation



extension String {
	
	func safeString(forChars safeChars: Character...) -> String {
		assert(!safeChars.contains("\\"))
		var res = replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "\r", with: "\\r")
		for char in safeChars {
			res = res.replacingOccurrences(of: String(char), with: "\\\(char)")
		}
		return res
	}
	
}



class StandardErrorOutputStream: TextOutputStream {
	
	func write(_ string: String) {
		let stderr = FileHandle.standardError
		stderr.write(string.data(using: String.Encoding.utf8)!)
	}
	
}

class StandardOutputStream: TextOutputStream {
	
	func write(_ string: String) {
		let stderr = FileHandle.standardOutput
		stderr.write(string.data(using: String.Encoding.utf8)!)
	}
	
}

var mx_stdout = StandardOutputStream()
var mx_stderr = StandardErrorOutputStream()
