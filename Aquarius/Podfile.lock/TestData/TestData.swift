//
//  TestData.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/11/30.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

#if DEBUG
import Foundation

let testData = createTestData()
func createTestData() -> UserData {
    let testData = UserData()
    let testReader = DataReader(path: Bundle.main.path(forResource: "Podfile", ofType: "lock"))

    if let lock = testReader.readData() {
        testData.lock = lock
        if let pod = lock.pods.first {
            testData.detail = [Detail(index: 0, content: .pod(pod))]
        }
    }
    return testData
}
#endif
