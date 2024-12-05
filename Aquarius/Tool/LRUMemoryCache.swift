//
//  LRUMemoryCache.swift
//  Aquarius
//
//  Created by Crazy凡 on 2024/11/9.
//

/*
import Foundation

class LRUMemoryCache<Key: Hashable, Value> {
    private struct CacheItem {
        let value: Value
        let cost: Int
        var date: Date
    }

    private var cache = [Key: CacheItem]()
    private var totalCost = 0
    private let maxCost: Int
    private let maxCount: Int
    private let lock = NSLock()

    init(maxCost: Int, maxCount: Int) {
        self.maxCost = maxCost
        self.maxCount = maxCount
    }

    subscript(key: Key) -> Value? {
        get {
            lock.lock()
            defer { lock.unlock() }
            if let item = cache[key] {
                cache[key]?.date = Date() // Update access time
                return item.value
            }
            return nil
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            if let value = newValue {
                let cost = LRUMemoryCache.calculateCost(of: value)
                if let oldItem = cache[key] {
                    // Remove old value cost
                    totalCost -= oldItem.cost
                }
                cache[key] = CacheItem(value: value, cost: cost, date: Date())
                totalCost += cost
                cleanUpIfNeeded()
            } else {
                if let item = cache.removeValue(forKey: key) {
                    totalCost -= item.cost
                }
            }
        }
    }

    private func cleanUpIfNeeded() {
        while totalCost > maxCost || cache.count > maxCount {
            if let leastUsedKey = cache.min(by: { $0.value.date < $1.value.date })?.key {
                if let item = cache.removeValue(forKey: leastUsedKey) {
                    totalCost -= item.cost
                }
            }
        }
    }

    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll()
        totalCost = 0
    }

    private static func calculateCost(of value: Any) -> Int {
        if let data = value as? Data {
            return data.count
        }
        if let array = value as? [Any] {
            return array.reduce(0) { $0 + calculateCost(of: $1) }
        }
        if let dict = value as? [AnyHashable: Any] {
            return dict.reduce(0) { $0 + calculateCost(of: $1.value) }
        }
        return MemoryLayout.size(ofValue: value)
    }
}
*/
