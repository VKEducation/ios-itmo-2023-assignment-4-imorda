import Foundation

open class Task {
    private var dependencies: Int = 0 {
        willSet {
            if newValue > 0, state == State.ready {
                state = State.blocked
            }
        }
        
        didSet {
            if dependencies == 0, state == State.blocked {
                state = State.ready
            }
        }
    }
    
    private var subscribers: [Task] = []
    private let subscribersLock: NSLock = .init()
    
    enum State: String {
        case ready, blocked, executing, finished, cancelled
    }
    
    private var state = State.ready {
        didSet {
            let newState = state
            if newState == State.finished || newState == State.cancelled {
                subscribersLock.withLock {
                    for i in subscribers {
                        if newState == State.finished {
                            i.dependencies -= 1
                        } else if newState == State.cancelled {
                            i.cancel()
                        }
                    }
                    subscribers.removeAll()
                }
            }
        }
    }
    
    public func cancel() {
        state = State.cancelled
    }
    
    func isCancelled() -> Bool {
        return state == State.cancelled
    }

    func isBlocked() -> Bool {
        return state == State.blocked
    }

    func isReady() -> Bool {
        return state == State.ready
    }

    func isExecuting() -> Bool {
        return state == State.executing
    }

    func isFinished() -> Bool {
        return state == State.finished
    }

    let priority: DispatchQoS
    
    private func subscribe(_ task: Task) -> Bool {
        subscribersLock.withLock {
            if state == State.cancelled || state == State.finished {
                return false
            }
            subscribers.append(task)
            return true
        }
    }
    
    public func addDependency(_ task: Task) {
        if task.subscribe(self) {
            dependencies += 1
        } else if task.state == State.cancelled {
            cancel()  // cascade cancellation
        }
    }
    
    public init(priority: DispatchQoS = .default) {
        self.priority = priority
    }
    
    func execute() {
        state = State.executing
        main()
        state = State.finished
    }
    
    open func main() {}
}

class TaskManager {
    private var tasks: [Task] = []
    private let queue = DispatchQueue(label: "TaskManager", attributes: .concurrent)
    
    func add(_ task: Task) {
        if !runIfpossible(task) {
            tasks.append(task)
        }
    }
    
    @discardableResult
    func runIfpossible(_ task: Task) -> Bool {
        if task.isReady() {
            queue.async(qos: task.priority) {
                task.execute()
                self.runAllReady()
            }
            return true
        }
        return false
    }
    
    func runAllReady() {
        for i in (0 ..< tasks.count).reversed() {
            if tasks[i].isCancelled() || runIfpossible(tasks[i]) {
                tasks.remove(at: i)
            }
        }
    }
}
