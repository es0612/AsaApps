//
//  AsaVRDiaryUITests.swift
//  AsaVRDiaryUITests
//
//  UIテスト
//

import XCTest

final class AsaVRDiaryUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
