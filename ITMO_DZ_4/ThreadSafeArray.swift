import Foundation

class ThreadSafeArray<T> {
    private var array: [T] = []
    private let lock = RWLock()
    
    public func append(_ value: Element) {
        lock.withWriteLock { array.append(value) }
    }
    
    @discardableResult
    public func remove(at index: Int) -> Element {
        lock.withWriteLock { array.remove(at: index) }
    }
    
    public func insert(_ newElement: Element, at i: Int) {
        lock.withWriteLock { array.insert(newElement, at: i) }
    }
    
    public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        lock.withWriteLock { array.removeAll() }
    }
    
    public func reserveCapacity(_ minimumCapacity: Int) {
        lock.withWriteLock { array.reserveCapacity(minimumCapacity) }
    }
    
    public func toString() -> String {
        lock.withReadLock { "\(array)" }
    }
}

extension ThreadSafeArray: RandomAccessCollection, MutableCollection {
    typealias Index = Int
    typealias Element = T
    
    public var startIndex: Int {
        lock.withReadLock { array.startIndex }
    }
    
    public var endIndex: Int {
        lock.withReadLock { array.endIndex }
    }

    public subscript(position: Int) -> T {
        get {
            lock.withReadLock { array[position] }
        }
        
        set {
            lock.withWriteLock { array[position] = newValue }
        }
    }
        
    public func index(after i: Index) -> Index {
        lock.withReadLock { array.index(after: i) }
    }
}
