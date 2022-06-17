//
//  GoNoGoStepObject.swift
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

import Foundation
import JsonModel
import AssessmentModel

extension SerializableNodeType {
    static let gonogo: SerializableNodeType = "gonogo"
}

struct GoNoGoStepObject : SerializableNode, Step, Codable {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case serializableType = "type", identifier
        
        case detail
        
        // Parameters
        case _maximumStimulusInterval = "maximumStimulusInterval",
             _minimumStimulusInterval = "minimumStimulusInterval",
             _thresholdAcceleration = "thresholdAcceleration",
             _numberOfAttempts = "numberOfAttempts",
             _timeout = "timeout"
    }
    
    private(set) var serializableType: SerializableNodeType = .gonogo
    let identifier: String
    
    /// Localized instruction string included in JSON file.
    let detail: String
    
    /// The maximum interval before the stimulus is delivered.
    var maximumStimulusInterval: TimeInterval { _maximumStimulusInterval ?? 10.0 }
    private(set) var _maximumStimulusInterval: TimeInterval?
    
    /// The minimum interval before the stimulus is delivered.
    var minimumStimulusInterval: TimeInterval { _minimumStimulusInterval ?? 4.0 }
    private(set) var _minimumStimulusInterval: TimeInterval?
    
    /// The acceleration required to end a reaction time test.
    var thresholdAcceleration: Double { _thresholdAcceleration ?? 0.5 }
    private(set) var _thresholdAcceleration: Double?
    
    /// The number of successful attempts required before the task is complete. The active step result will contain
    /// this many child results if the task is completed.
    var numberOfAttempts: Int { _numberOfAttempts ?? 9 }
    private(set) var _numberOfAttempts: Int?
    
    /// The interval permitted after the stimulus until the test fails, if the threshold is not reached.
    var timeout: TimeInterval { _timeout ?? 3.0 }
    private(set) var _timeout: TimeInterval?
    
    init() {
        self.identifier = SerializableNodeType.gonogo.rawValue
        self.detail = "Quickly shake the device when the blue dot appears. Do not shake for a green dot."
    }
    
    func instantiateResult() -> ResultData {
        GoNoGoResultObject(identifier: self.identifier)
    }
    
    // Step implementations - ignored
    
    var comment: String? { nil }
    
    func button(_ buttonType: ButtonType, node: Node) -> ButtonActionInfo? {
        nil
    }
    
    func shouldHideButton(_ buttonType: ButtonType, node: Node) -> Bool? {
        nil
    }
    
    func spokenInstruction(at timeInterval: TimeInterval) -> String? {
        nil
    }
}
