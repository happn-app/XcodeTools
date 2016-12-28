/*
 * stdio.swift
 * hagvtool
 *
 * Created by François Lamboley on 12/15/16.
 * Copyright © 2016 happn. All rights reserved.
 */

import Foundation



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
