import XCTest
@testable import BiAffectSDK

final class BiAffectSDKTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        // XCTAssertEqual(BiAffectSDK().text, "Hello, World!")
    }
    
    func testAssessmentDecoding_GoNoGo() {
        do {
            let identifier = BiAffectIdentifier.goNoGo
            let _ = try identifier.instantiateAssessmentState()
        }
        catch {
            XCTFail("Failed to build assessment. \(error)")
        }
    }
    
    // TODO: syoung 06/09/2022 Add "countdown" step to AssessmentModel library
//    func testAssessmentDecoding_TrailMaking() {
//        do {
//            let identifier = BiAffectIdentifier.trailmaking
//            let _ = try identifier.instantiateAssessmentState()
//        }
//        catch {
//            XCTFail("Failed to build assessment. \(error)")
//        }
//    }
}
