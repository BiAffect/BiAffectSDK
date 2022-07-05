//
//  Copyright © 2022 BiAffect. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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

