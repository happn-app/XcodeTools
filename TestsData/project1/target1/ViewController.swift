/*
 * ViewController.swift
 * Target 1
 *
 * Created by François Lamboley on 11/09/2020.
 */

import Cocoa



class ViewController: NSViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
//		print("“\(Bundle.main.infoDictionary!["TEST_SPACES"]!)”")
//		print("“\(Bundle.main.infoDictionary!["TEST_INCLUDES"]!)”")
//		print("“\(Bundle.main.infoDictionary!["TEST_INCLUDES_2"]!)”")
		for (k, v) in Bundle.main.infoDictionary!.sorted(by: { $0.key < $1.key }) {
			print("“\(k)” -> “\(v)”")
		}
		NSApplication.shared.terminate(nil)
	}
	
}
