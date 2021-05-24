//
//  AsynchronousOperation.swift
//  TripUp
//
//  Created by Vasily Ulianov on 09.02.17, updated in 2019.
//  License: MIT

import Foundation

/// Subclass of `Operation` that adds support of asynchronous operations.
/// 1. Call `super.main()` when override `main` method.
/// 2. When operation is finished or cancelled set `state = .finished` or `finish()`
open class AsynchronousOperation: Operation {
    public override var isAsynchronous: Bool {
        return true
    }

    public override var isExecuting: Bool {
        return state == .executing
    }

    public override var isFinished: Bool {
        return state == .finished
    }

    public override func start() {
        if self.isCancelled {
            state = .finished
        } else {
            state = .ready
            main()
        }
    }

    open override func main() {
        if self.isCancelled {
            state = .finished
        } else {
            state = .executing
        }
    }

    public func finish() {
        state = .finished
    }

    // MARK: - State management

    public enum State: String {
        case ready = "Ready"
        case executing = "Executing"
        case finished = "Finished"
        fileprivate var keyPath: String { return "is" + self.rawValue }
    }

    /// Thread-safe computed state value
    public var state: State {
        get {
            stateQueue.sync {
                return stateStore
            }
        }
        set {
            let oldValue = state
            willChangeValue(forKey: state.keyPath)
            willChangeValue(forKey: newValue.keyPath)
            stateQueue.sync(flags: .barrier) {
                stateStore = newValue
            }
            didChangeValue(forKey: state.keyPath)
            didChangeValue(forKey: oldValue.keyPath)
        }
    }

    private let stateQueue = DispatchQueue(label: "AsynchronousOperation State Queue", attributes: .concurrent)

    /// Non thread-safe state storage, use only with locks
    private var stateStore: State = .ready
}
