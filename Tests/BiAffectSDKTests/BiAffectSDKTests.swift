import XCTest
@testable import BiAffectSDK

final class BiAffectSDKTests: XCTestCase {
    
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
