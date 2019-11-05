//
//  Qu.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 10/24/15.
//  Copyright © 2015 lowriDevs. All rights reserved.
//

public typealias Block = () -> ()

// MARK: Qu

public class Qu {
    
    // MARK: Priority Enumeration
    
    public enum Priority {
        case Background
        case Main
        case Custom(OperationQueue)
        
        var queue: OperationQueue {
            switch self {
            case .Background:
                return OperationQueue()
            case .Main:
                return OperationQueue.main
            case .Custom(let customQueue):
                return customQueue
            }
        }
    }
    
    public enum Dependency {
        case Last
        case All
        case Previous(Int)
    }
    
    // MARK: Properties
    
    private(set) var priority: Priority
    private(set) var operationQueue: OperationQueue
    
    /// Completion operation that will attempt to wait for other operations to finish and then execute.  If all operations have already executed before this operation is added, it will run immediately.  Even if you add operations afterwards.
    private(set) var completion: Operation? {
        willSet {
            if completion != nil && newValue != nil {
                print("*** Warning *** Setting multiple completion blocks will result in unpredictable behavior!")
            }
        }
    }
    
    // MARK: Initialization
    
    public required init(priority: Priority) {
        self.priority = priority
        self.operationQueue = priority.queue
    }
    
    // MARK: Class Functions

    @discardableResult
    class func Background(_ block: @escaping Block) -> Self {
        let q = self.init(priority: .Background)
        return q.Run(block)
    }

    @discardableResult
    class func Main(_ block: @escaping Block) -> Self {
        let q = self.init(priority: .Main)
        return q.Run(block)
    }
    
    class func Custom(_ queue: OperationQueue, block: @escaping Block) -> Self {
        let q = self.init(priority: .Custom(queue))
        return q.Run(block)
    }
    
    // MARK: Dispatching Functions
    
    func Run(_ block: @escaping Block) -> Self {
        return queue(block)
    }
    
    func Also(_ block: @escaping Block) -> Self {
        return queue(block)
    }
    
    func Then(_ block: @escaping Block) -> Self {
        return ThenAfter(.Last, block: block)
    }
    
    func ThenAfter(_ dependency: Dependency, block: @escaping Block) -> Self {
        let blockOp = Operation(block: block)
        switch dependency {
        case .Last:
            if let last = operationQueue.lastOperation {
                blockOp.addDependency(last)
            }
        case .Previous(let previousOperationCount):
            let ops = operationQueue.ops
            let count = ops.count
            let start = count - previousOperationCount
            let dependentOperations = ops[start..<count]
            for op in dependentOperations {
                blockOp.addDependency(op)
            }
        case .All:
            for op in operationQueue.ops {
                blockOp.addDependency(op)
            }
        }
        return queue(blockOp)
    }
    
    // MARK: Completion
    
    func Finally(_ block: @escaping Block) -> Self {
        let op = Operation(block: block)
        completion = op
        operationQueue.setCompletion(op)
        return self
    }
    
    func FinallyOn(_ priority: Priority, block: @escaping Block) -> Self {
        let wrapped: Block = {
            if let queue = priority.queue.underlyingQueue {
                queue.async(execute: block)
            }
        }
        return Finally(wrapped)
    }
    
    // MARK: Queueing
    
    private func queue(_ block: @escaping Block) -> Self {
        return queue(Operation(block: block))
    }
    
    private func queue(_ op: Operation) -> Self {
        if let completion = completion {
            completion.addDependency(op)
        }
        operationQueue += op
        return self
    }
}

// MARK: Operation

class Operation : BlockOperation {
    
    private(set) var block: Block!
    
    init(block: @escaping Block) {
        super.init()
        self.block = block
        addExecutionBlock(self.block)
    }
}

extension Operation {
    override var description: String {
        return name ?? "[unnamed]"
    }
}

// MARK: Operators

func +=(operationQueue: OperationQueue, block: @escaping Block) {
    operationQueue.addOperation(block)
}
func +=(operationQueue: OperationQueue, operation: Operation) {
    operationQueue.addOperation(operation)
}

// MARK: OperationQueue+Operations

private extension OperationQueue {
    
    /// This is the most recently added operation.  According to the docs, `operation` is returned in the order they were added to the queue, NOT the order in which they are executed.
    var lastOperation: Operation? {
        return ops.last
    }
    
    var ops: [Operation] {
        return operations as? [Operation] ?? []
    }
    
    func setCompletion(_ block: @escaping Block) -> Operation {
        let blockOp = Operation(block: block)
        return setCompletion(blockOp)
    }
    
    func setCompletion(_ blockOp: Operation) -> Operation {
        for op in ops {
            blockOp.addDependency(op)
        }
        addOperation(blockOp)
        return blockOp
    }
}
