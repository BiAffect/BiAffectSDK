//

import SwiftUI
import MobilePassiveData
import MotionSensor
import AssessmentModel
import AssessmentModelUI
import JsonModel

let kBaseJsonSchemaURL = URL(string: "https://biaffect.github.io/biaffectsdk/json/schemas/v1/")!

public enum BiAffectIdentifier : String, CaseIterable {
    case trailmaking = "Trail_Making", goNoGo = "Go-No-Go"
    
    public func title() -> Text {
        switch self {
        case .trailmaking:
            return Text("Trail Making", bundle: .module)
        case .goNoGo:
            return Text("Go No Go", bundle: .module)
        }
    }
    
    public func icon() -> ContentImage {
        .init(self.rawValue, bundle: .module)
    }
    
    public func instantiateAssessmentState() throws -> AssessmentState {
        let filename = self.rawValue
        guard let url = Bundle.module.url(forResource: filename, withExtension: "json")
        else {
            throw ValidationError.unexpectedNullObject("Could not find JSON file \(filename).")
        }
        let data = try Data(contentsOf: url)
        let factory = BiAffectFactory()
        let decoder = factory.createJSONDecoder()
        let assessment = try decoder.decode(AssessmentObject.self, from: data)
        return .init(assessment)
    }
}

final class BiAffectFactory : AssessmentFactory {
    required init() {
        super.init()
        
        self.nodeSerializer.add(GoNoGoStepObject())
        self.nodeSerializer.add(TrailmakingStepObject())
        
        self.resultSerializer.add(GoNoGoResultObject())
        self.resultSerializer.add(TrailmakingResultObject())
    }
    
    override func resourceBundle(for bundleInfo: DecodableBundleInfo, from decoder: Decoder) -> ResourceBundle? {
        Bundle.module
    }
}

