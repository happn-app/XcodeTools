import Foundation

import SignalHandling
import SystemPackage

import Utils



public struct ProcessRawOutputIterator : AsyncIteratorProtocol {
	
	public struct LineWithSource : Equatable {
		
		public var line: Data
		public var eol: Data
		
		public var fd: FileDescriptor
		
		public var utf8Line: String {
			get throws {
				return try String(data: line, encoding: .utf8).get(orThrow: Err.nonUtf8Output(line))
			}
		}
		
		public var utf8EOL: String {
			get throws {
				return try String(data: line, encoding: .utf8).get(orThrow: Err.nonUtf8Output(line))
			}
		}
		
	}
	
	public typealias Element = LineWithSource
	
	public init(
		_ executable: FilePath, args: [String] = [], usePATH: Bool = false, customPATH: [FilePath]?? = nil,
		workingDirectory: URL? = nil, environment: [String: String]? = nil,
		stdin: FileDescriptor? = FileDescriptor.standardInput,
		stdoutRedirect: Process.RedirectMode = .capture,
		stderrRedirect: Process.RedirectMode = .capture,
		fileDescriptorsToSend: [FileDescriptor /* Value in parent */: FileDescriptor /* Value in child */] = [:],
		additionalOutputFileDescriptors: Set<FileDescriptor> = [],
		signalsToForward: Set<Signal> = Signal.toForwardToSubprocesses,
		lineSeparators: Process.LineSeparators = .default
	) throws {
		let s = State()
		let p = try Process.spawnedAndStreamedProcess(
			executable, args: args, usePATH: usePATH, customPATH: customPATH,
			workingDirectory: workingDirectory, environment: environment,
			stdin: stdin, stdoutRedirect: stdoutRedirect, stderrRedirect: stderrRedirect,
			fileDescriptorsToSend: fileDescriptorsToSend, additionalOutputFileDescriptors: additionalOutputFileDescriptors,
			signalsToForward: signalsToForward,
			outputHandler: s.processNewLine /* ok to call unsynchronized, because called from stream group (not “public” knowledge, but I know) */,
			lineSeparators: lineSeparators,
			terminationHandler: { p in Process.streamQueue.sync(execute: s.processEndOfProcess) },
			ioDispatchGroup: s.ioDispatchGroup
		)
		state = s
		process = p
		
		s.waitForDataGroup.enter()
		s.waitingForData = true
	}
	
	public mutating func next() async throws -> LineWithSource? {
		let s = state
		return await withCheckedContinuation{ continuation in
			state.waitForDataGroup.notify(queue: Process.streamQueue, execute: {
				guard let l = s.bufferedLines.first else {
					return continuation.resume(returning: nil)
				}
				s.bufferedLines.removeFirst()
				return continuation.resume(returning: l)
			})
		}
	}
	
	/** It is a programer error to call this while the iteration is not over. */
	public var terminationStatus: Int32 {
		process.terminationStatus
	}
	
	public var terminationReason: Process.TerminationReason {
		process.terminationReason
	}
	
	public func checkNormalExit(expectBrokenPipe: Bool = false) throws {
		guard (                    terminationStatus == 0                          && terminationReason == .exit) ||
				(expectBrokenPipe && terminationStatus == Signal.brokenPipe.rawValue && terminationReason == .uncaughtSignal)
		else {
			throw Err.unexpectedSubprocessExit(terminationStatus: terminationStatus, terminationReason: terminationReason)
		}
	}
	
	/* Sometimes, check if can be made an actor… */
	private class State {
		
		var processIsDone = false
		var bufferedLines = [LineWithSource]()
		
		let ioDispatchGroup = DispatchGroup()
		
		var waitingForData = false
		let waitForDataGroup = DispatchGroup()
		
		func processEndOfProcess() {
			assert(!processIsDone)
			processIsDone = true
			ioDispatchGroup.notify(queue: Process.streamQueue, execute: {
				if self.waitingForData {
					self.waitingForData = false
					self.waitForDataGroup.leave()
				}
			})
		}
		
		func processNewLine(line: Data, eol: Data, sourceFd: FileDescriptor, signalEOI: () -> Void, process: Process) {
			bufferedLines.append(LineWithSource(line: line, eol: eol, fd: sourceFd))
			if waitingForData {
				waitingForData = false
				waitForDataGroup.leave()
			}
		}
		
	}
	
	private var state: State
	
	private let process: Process
	
}


public struct ProcessUtf8OutputIterator : AsyncIteratorProtocol {
	
	public struct LineWithSource : Equatable {
		
		public var line: String
		public var eol: String
		
		public var fd: FileDescriptor
		
	}
	
	public typealias Element = LineWithSource
	
	public mutating func next() async throws -> LineWithSource? {
		return try await rawOutputIterator.next().flatMap{ try LineWithSource(line: $0.utf8Line, eol: $0.utf8EOL, fd: $0.fd) }
	}
	
	private var rawOutputIterator: ProcessRawOutputIterator
	
}
