//
//  CopyTaskEngine.swift
//  Aquarius
//
//  Created by Crazy凡 on 2023/11/27.
//

import Foundation

actor CopyTaskEngine<ResultType> {
    actor Task {
        var result: ResultType?
        private var task: () async -> ResultType
        private var observers: [(_ result: ResultType) -> Void] = []
        private var isRuning: Bool = false

        init(result: ResultType? = nil, task: @escaping () async -> ResultType) {
            self.result = result
            self.task = task
        }

        func addObserver() async -> ResultType {
            if let result { return result }
            return await withCheckedContinuation { c in
                observers.append({ c.resume(returning: $0) })
            }
        }

        func cancel() {
            observers.removeAll()
        }

        func run() async {
            guard !isRuning else { return }
            isRuning = true

            let result = await task()
            self.result = result
            observers.forEach { observer in
                observer(result)
            }
            observers.removeAll()
        }
    }

    var tasks: [String: Task] = .init()

    func cancelAllTasks() async {
        for task in tasks.values {
            await task.cancel()
        }
    }

    func value(for name: String, createTask: @autoclosure () -> (() async -> ResultType)) async -> ResultType {
        let task = tasks[name] ?? Task(task: createTask())
        if !tasks.keys.contains(name) {
            tasks[name] = task
        }
        if let result = await task.result {
            return result
        } else {
            await task.run()
            return await task.addObserver()
        }
    }
}
