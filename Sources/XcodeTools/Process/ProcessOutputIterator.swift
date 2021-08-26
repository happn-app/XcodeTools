import Foundation

import SignalHandling
import SystemPackage

import Utils


/*
public struct ProcessRawOutputIterator : AsyncIteratorProtocol {
	
	public init(
		_ executable: FilePath, args: [String] = [], usePATH: Bool = false, customPATH: [FilePath]?? = nil,
		workingDirectory: URL? = nil, environment: [String: String]? = nil,
		stdin: FileDescriptor? = FileDescriptor.standardInput,
		stdoutRedirect: RedirectMode = .capture,
		stderrRedirect: RedirectMode = .capture,
		fileDescriptorsToSend: [FileDescriptor /* Value in parent */: FileDescriptor /* Value in child */] = [:],
		additionalOutputFileDescriptors: Set<FileDescriptor> = [],
		signalsToForward: Set<Signal> = Signal.toForwardToSubprocesses,
		lineSeparators: LineSeparators = .default
	) throws {
		let s = State()
		let p = try Process.spawnedAndStreamedProcess(
			executable, args: args, usePATH: usePATH, customPATH: customPATH,
			workingDirectory: workingDirectory, environment: environment,
			stdin: stdin, stdoutRedirect: stdoutRedirect, stderrRedirect: stderrRedirect,
			fileDescriptorsToSend: fileDescriptorsToSend, additionalOutputFileDescriptors: additionalOutputFileDescriptors,
			signalsToForward: signalsToForward,
			lineSeparators: lineSeparators,
			outputHandler: s.processNewLine /* ok to call unsynchronized, because called from stream group (not “public” knowledge, but I know) */,
			terminationHandler: { p in Process.streamQueue.sync(execute: s.processEndOfProcess) },
			ioDispatchGroup: s.ioDispatchGroup
		)
		state = s
		process = p
		
		s.waitingForData = true
		s.waitForDataGroup.enter()
	}
	
	public mutating func next() async throws -> RawLineWithSource? {
		try Task.checkCancellation()
		
		let s = state
		return try await withCheckedThrowingContinuation{ continuation in
			state.waitForDataGroup.notify(queue: Process.streamQueue, execute: {
				guard let l = s.bufferedLines.first else {
					return continuation.resume(returning: nil)
				}
				s.bufferedLines.removeFirst()
				if s.bufferedLines.isEmpty {
					s.waitingForData = true
					s.waitForDataGroup.enter()
				}
				
				switch l {
					case .success(let l): return continuation.resume(returning: l)
					case .failure(let e): return continuation.resume(throwing: e)
				}
			})
		}
	}
	
	/** It is a programer error to call this while the iteration is not over. */
	public var terminationStatus: Int32 {
		assert(state.processIsDone)
		return process.terminationStatus
	}
	
	/** It is a programer error to call this while the iteration is not over. */
	public var terminationReason: Process.TerminationReason {
		assert(state.processIsDone)
		return process.terminationReason
	}
	
	public func checkNormalExit(expectBrokenPipe: Bool = false) throws {
		guard (                    terminationStatus == 0                          && terminationReason == .exit) ||
				(expectBrokenPipe && terminationStatus == Signal.brokenPipe.rawValue && terminationReason == .uncaughtSignal)
		else {
			throw Err.unexpectedSubprocessExit(terminationStatus: terminationStatus, terminationReason: terminationReason)
		}
	}
	
	/* Maybe later, check if can be made an actor… */
	private class State {
		
		var processIsDone = false
		var gotOutputError = false
		var bufferedLines = [Result<RawLineWithSource, Error>]()
		
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
		
		func processNewLine(lineResult: Result<RawLineWithSource, Error>, signalEOI: () -> Void, process: Process) {
			guard !gotOutputError else {return}
			gotOutputError = ((try? lineResult.get()) == nil)
			
			bufferedLines.append(lineResult)
			if waitingForData {
				waitingForData = false
				waitForDataGroup.leave()
			}
		}
		
	}
	
	private let process: Process
	private var state: State
	
}
*/
