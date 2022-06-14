//
//  GoNoGoStepView.swift
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
import SharedMobileUI
import JsonModel
import Combine
import MobilePassiveData

#if canImport(CoreMotion)
import CoreMotion
#endif

struct GoNoGoStepView: View {
    @EnvironmentObject var assessmentState: AssessmentState
    @EnvironmentObject var pagedNavigation: PagedNavigationViewModel
    @ObservedObject var nodeState: StepState
    @StateObject var viewModel: ViewModel = .init()
    
    init(_ nodeState: StepState) {
        self.nodeState = nodeState
    }
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            .onAppear {
                viewModel.isVisible = true
            }
            .onDisappear {
                viewModel.isVisible = false
            }
            .onReceive(motionShaked) {
                viewModel.onMotionShaked()
            }
    }
    
    @MainActor
    class ViewModel : ObservableObject {
        @Published var isVisible: Bool = false
        @Published var attemptCount: Int = 0
        @Published var errorCount: Int = 0
        @Published var lastReactionTime: TimeInterval?
        @Published var go: Bool = false
        @Published var incorrect: Bool = false
        @Published var testState: TestState = .waiting
        @Published var motionDenied: Bool = false
        
        enum TestState : Int {
            case waiting, showingStimulus, showingResult
        }
        
        var result: GoNoGoResultObject?
        var samples: [GoNoGoResultObject.Sample] = []
        var clock: SystemClock = .init()
        var thresholdUptime: TimeInterval?
        var stimulusUptime: TimeInterval?
        var motionSensorsActive: Bool = false
        
        func onAppear(_ nodeState: StepState) {
            guard !isVisible else { return }
            isVisible = true
            result = nodeState.result as? GoNoGoResultObject
            
        }
        
        func onDisappear() {
            guard isVisible else { return }
            isVisible = false
        }
        
        func onMotionShaked() {
            guard isVisible, !motionSensorsActive else { return }
            thresholdUptime = ProcessInfo.processInfo.systemUptime
            didFinishAttempt()
        }
        
        func didFinishAttempt() {
            
        }
        
    }
}

struct GoNoGoStepView_Previews: PreviewProvider {
    static var previews: some View {
        GoNoGoStepView(StepState(step: GoNoGoStepObject()))
    }
}

let motionShaked = PassthroughSubject<Void, Never>()

#if canImport(UIKit)
import UIKit

extension UIWindow {
     open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            motionShaked.send()
        }
     }
}

#endif

//
//// A view modifier that detects shaking and calls a function of our choosing.
//struct DeviceShakeViewModifier: ViewModifier {
//    let action: () -> Void
//
//    func body(content: Content) -> some View {
//        content
//            .onAppear()
//            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
//                action()
//            }
//    }
//}
//
//// A View extension to make the modifier easier to use.
//extension View {
//    func onShake(perform action: @escaping () -> Void) -> some View {
//        self.modifier(DeviceShakeViewModifier(action: action))
//    }
//}
