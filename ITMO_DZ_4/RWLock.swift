import Foundation

class RWLock {
    private var lock = pthread_rwlock_t()

    public init() {
        guard pthread_rwlock_init(&lock, nil) == 0 else {
            fatalError("Lock not created")
        }
    }

    deinit {
        pthread_rwlock_destroy(&lock)
    }

    public func withReadLock<R>(_ body: () throws -> R) rethrows -> R {
        readLock()
        defer { unlock() }
        return try body()
    }

    public func withWriteLock<R>(_ body: () throws -> R) rethrows -> R {
        writeLock()
        defer { unlock() }
        return try body()
    }

    @discardableResult
    func writeLock() -> Bool {
        pthread_rwlock_wrlock(&lock) == 0
    }

    @discardableResult
    func readLock() -> Bool {
        pthread_rwlock_rdlock(&lock) == 0
    }

    @discardableResult
    func unlock() -> Bool {
        pthread_rwlock_unlock(&lock) == 0
    }
}
