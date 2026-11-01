import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(Camera_SwiftUITests.allTests),
    ]
}
#endif
