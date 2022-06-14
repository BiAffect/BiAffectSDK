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

//@param maximumStimulusInterval     The maximum interval before the stimulus is delivered.
//@param minimumStimulusInterval     The minimum interval before the stimulus is delivered.
//@param thresholdAcceleration       The acceleration required to end a reaction time test. Default = `0.5`.
//@param numberOfAttempts            The number of successful attempts required before the task is
//complete. The active step result will contain this many
//child results if the task is completed.
//@param timeout                     The interval permitted after the stimulus until the test fails,
//if the threshold is not reached.

extension SerializableNodeType {
    static let gonogo: SerializableNodeType = "gonogo"
}

//final class GoNoGoStepObject : AbstractStepObject, Encodable {
//    override class func defaultType() -> SerializableNodeType {
//        .gonogo
//    }
//
//    override func instantiateResult() -> ResultData {
//        GoNoGoResultObject(identifier: self.identifier)
//    }
//}

struct GoNoGoStepObject : SerializableNode, Step, Codable {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case serializableType = "type", identifier
    }
    
    private(set) var serializableType: SerializableNodeType = .gonogo
    let identifier: String
    
    init() {
        self.identifier = SerializableNodeType.gonogo.rawValue
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
