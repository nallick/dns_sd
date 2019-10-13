import dns_sd
import XCTest

final class dns_sdTests: XCTestCase {

    override func setUp() {
        super.setUp()
        DNSService.disableExternalWarnings()
    }

    func testKeyAddedIsContained() {
        let testKey = "testKey"
        let txtRecord = TXTRecord()

        let error = txtRecord.setValue(forKey: testKey, value: "testValue")
        let isContained = txtRecord.contains(key: testKey)

        XCTAssertEqual(error, .noError)
        XCTAssertTrue(isContained)
    }

    func testKeyRemovedIsContained() {
        let testKey = "testKey"
        let txtRecord = TXTRecord()

        let addError = txtRecord.setValue(forKey: testKey, value: "testValue")
        let wasContained = txtRecord.contains(key: testKey)
        let removeError = txtRecord.removeValue(forKey: testKey)
        let isContained = txtRecord.contains(key: testKey)

        XCTAssertEqual(addError, .noError)
        XCTAssertEqual(removeError, .noError)
        XCTAssertTrue(wasContained)
        XCTAssertFalse(isContained)
    }

    func testValueAddedIncrementsCount() {
        let testKey = "testKey"
        let txtRecord = TXTRecord()

        let initialCount = txtRecord.count
        let error = txtRecord.setValue(forKey: testKey, value: "testValue")
        let finalCount = txtRecord.count

        XCTAssertEqual(error, .noError)
        XCTAssertEqual(initialCount, 0)
        XCTAssertEqual(finalCount, 1)
    }

    func testValueAddedForKeyCanBeExtractedByKey() {
        let testKey = "testKey"
        let expectedValue = "testValue"
        let txtRecord = TXTRecord()

        let error = txtRecord.setValue(forKey: testKey, value: expectedValue)
        let actualValue = txtRecord.string(forKey: testKey)

        XCTAssertEqual(error, .noError)
        XCTAssertEqual(actualValue, expectedValue)
    }

    func testValueAddedForKeyCanBeExtractedByKeyValue() {
        let expectedKey = "testKey"
        let expectedValue = "testValue"
        let txtRecord = TXTRecord()

        let error = txtRecord.setValue(forKey: expectedKey, value: expectedValue)
        let actualKeyValuePair = try? txtRecord.keyValue(forIndex: 0)

        XCTAssertEqual(error, .noError)
        XCTAssertNotNil(actualKeyValuePair)
        XCTAssertEqual(actualKeyValuePair!.key, expectedKey)
        XCTAssertEqual(String(data: actualKeyValuePair!.value, encoding: .utf8), expectedValue)
    }

    static var allTests = [
        ("testKeyAddedIsContained", testKeyAddedIsContained),
        ("testKeyRemovedIsContained", testKeyRemovedIsContained),
        ("testValueAddedIncrementsCount", testValueAddedIncrementsCount),
        ("testValueAddedForKeyCanBeExtractedByKey", testValueAddedForKeyCanBeExtractedByKey),
        ("testValueAddedForKeyCanBeExtractedByKeyValue", testValueAddedForKeyCanBeExtractedByKeyValue),
    ]
}
