#!/usr/bin/swift
import Foundation

print(FileManager.default.currentDirectoryPath)
print(getenv("XCT_PROCESS_TEST_VALUE").flatMap{ String(cString: $0) } ?? "<no value>")
