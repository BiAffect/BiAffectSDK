//

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
    
    func testAssessmentDecoding_TrailMaking() {
        do {
            let identifier = BiAffectIdentifier.trailmaking
            let _ = try identifier.instantiateAssessmentState()
        }
        catch {
            XCTFail("Failed to build assessment. \(error)")
        }
    }
}
