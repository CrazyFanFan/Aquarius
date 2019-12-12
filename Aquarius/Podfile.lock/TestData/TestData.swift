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
func createTestData() -> DataAndSettings {
    let testData = DataAndSettings()
    if let path = Bundle.main.path(forResource: "Podfile", ofType: "lock") {
        let testReader = DataReader(fileURL: URL(fileURLWithPath: path))

        if let lock = testReader.readData(false) {
            testData.lock = lock
            if let pod = lock.pods.randomElement() {
                testData.onSelectd(pod: pod, with: 0)
            }
        }
    }

    return testData
}
#endif
