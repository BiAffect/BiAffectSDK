//
//  BiAffectAssessmentView.swift
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
import AssessmentModel
import AssessmentModelUI
import JsonModel
import SharedMobileUI

extension BiAffectAssessmentView : AssessmentDisplayView {
    public static func instantiateAssessmentState(_ identifier: String, config: Data?, restoredResult: Data?, interruptionHandling: InterruptionHandling?) throws -> AssessmentState {
        guard let taskId = BiAffectIdentifier(rawValue: identifier)
        else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "This view does not support \(identifier)"))
        }
        return try taskId.instantiateAssessmentState()
    }
}

/// Displays an assessment built using the views and model objects defined within this library.
public struct BiAffectAssessmentView : View {
    @StateObject var viewModel: AssessmentViewModel = .init()
    @ObservedObject var assessmentState: AssessmentState
    
    public init(_ assessmentState: AssessmentState) {
        self.assessmentState = assessmentState
    }
    
    public var body: some View {
        AssessmentWrapperView<StepView>(assessmentState, viewModel: viewModel)
    }
    
    struct StepView : View, StepFactoryView {
        @ObservedObject var state: StepState
        
        init(_ state: StepState) {
            self.state = state
        }
        
        var body: some View {
            if let step = state.step as? CompletionStep {
                CompletionStepView(step)
            }
            else if state.step is GoNoGoStepObject {
                GoNoGoStepView(state)
            }
            else if state.step is CountdownStep {
                CountdownStepView(state)
            }
            else if let nodeState = state as? ContentNodeState {
                InstructionStepView(nodeState, alignment: .center)
            }
            else {
                debugStepView(state)
            }
        }
        
        @ViewBuilder
        private func debugStepView(_ state: StepState) -> some View {
            VStack {
                Spacer()
                Text(state.id)
                Spacer()
                SurveyNavigationView()
            }
        }
    }
}

struct BiAffectAssessmentPreview : View {
    let assessmentState: AssessmentState
    
    init(_ identifier: BiAffectIdentifier) {
        assessmentState = try! identifier.instantiateAssessmentState()
    }
    
    var body: some View {
        BiAffectAssessmentView(assessmentState)
    }
}

struct BiAffectAssessmentView_Previews: PreviewProvider {
    static var previews: some View {
        BiAffectAssessmentPreview(.goNoGo)
    }
}

extension AssessmentObject {
    convenience init(previewStep: Step) {
        self.init(identifier: previewStep.identifier, children: [previewStep])
    }
}
