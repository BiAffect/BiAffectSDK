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

extension Font {
    static let instruction: Font = .latoFont(24, relativeTo: .title, weight: .regular)
    static let detail: Font = .latoFont(16, relativeTo: .footnote, weight: .regular)
}

struct GoNoGoStepView: View {
    @EnvironmentObject var assessmentState: AssessmentState
    @EnvironmentObject var pagedNavigation: PagedNavigationViewModel
    @ObservedObject var nodeState: StepState
    @StateObject var viewModel: ViewModel = .init()
    
    
    init(_ nodeState: StepState) {
        self.nodeState = nodeState
    }
    
    var body: some View {
        VStack {
            StepHeaderView(nodeState)
            instructions()
            Spacer()
            stimulus()
            Spacer()
        }
        .onAppear {
            viewModel.onAppear(nodeState)
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onReceive(motionShaked) {
            viewModel.onMotionShaked()
        }
        .onChange(of: viewModel.testState) { newValue in
            if newValue >= .finished {
                pagedNavigation.goForward()
            }
        }
        .onChange(of: assessmentState.showingPauseActions) { newValue in
            viewModel.paused = newValue
        }
    }
    
    @MainActor
    class ViewModel : ObservableObject {
        @Published var instructions: String = "Hello, World"
        @Published var isVisible: Bool = false
        @Published var attemptCount: Int = 0
        @Published var maxAttempts: Int = 9
        @Published var errorCount: Int = 0
        @Published var lastReactionTime: TimeInterval?
        @Published var go: Bool = false
        @Published var incorrect: Bool = false
        @Published var testState: TestState = .idle
        @Published var motionDenied: Bool = false
        @Published var showDot: Bool = false
        @Published var showResponse: Bool = false

        enum TestState : Int, Comparable {
            case idle, running, finished, error
        }
        
        @Published var paused: Bool = false {
            didSet {
                if !paused {
                    reset()
                }
            }
        }
        
        var result: GoNoGoResultObject!
        var step: GoNoGoStepObject!
        var samples: [GoNoGoResultObject.Sample] = []
        var clock: SystemClock!
        var thresholdUptime: TimeInterval?
        var stimulusUptime: TimeInterval?
        var motionSensorsActive: Bool = false
        
        deinit {
            
        }
        
        func onAppear(_ nodeState: StepState) {
            guard let result = nodeState.result as? GoNoGoResultObject,
                  let step = nodeState.step as? GoNoGoStepObject
            else {
                testState = .error
                return
            }
            guard !isVisible else { return }
            isVisible = true
            
            self.result = result
            self.step = step
            self.instructions = step.detail
            reset()
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
        
        func reset() {
            guard isVisible else { return }
            
            self.clock = .init()
            self.stimulusUptime = ProcessInfo.processInfo.systemUptime
            self.testState = .running
            self.showDot = false
            self.showResponse = false
        }
        
        func didFinishAttempt() {
            
            self.showDot = !incorrect
            self.showResponse = true
        }
    }
    
    @State var contentHeight: CGFloat = 0
    
    @ViewBuilder
    func instructions() -> some View {
        // Instructions and response - these are wrapped in a scrollview in case
        // the participant has extra large accessibility text turned on.
        ScrollView {
            VStack(alignment: .center, spacing: 4) {
                Text(viewModel.instructions)
                    .font(.instruction)
                    .padding(.bottom)
                Text("Attempt \(viewModel.attemptCount) of \(viewModel.maxAttempts)", bundle: .module)
                    .opacity(viewModel.attemptCount > 0 ? 1 : 0)
                    .font(.detail)
                if let reactionTime = viewModel.lastReactionTime {
                    Text("Last reaction time: \(reactionTime, specifier: "%.2f") seconds", bundle: .module)
                        .font(.detail)
                }
                Text("Errors: \(viewModel.errorCount)", bundle: .module)
                    .opacity(viewModel.errorCount > 0 ? 1 : 0)
                    .font(.detail)
            }
            .foregroundColor(.textForeground)
            .padding()
            .heightReader(height: $contentHeight)
        }
        .frame(maxHeight: contentHeight)
    }
    
    @ViewBuilder
    func stimulus() -> some View {
        ZStack {
            Circle()
                .fill(.blue)
                .opacity(viewModel.showDot && viewModel.go ? 1 : 0)
                .animation(.easeOut)
            Circle()
                .fill(.green)
                .opacity(viewModel.showDot && !viewModel.go ? 1 : 0)
                .animation(.easeOut)
            if viewModel.showResponse {
                if viewModel.incorrect {
                    XmarkView()
                }
                else {
                    CheckmarkView()
                }
            }
        }
        .frame(width: 128, height: 128, alignment: .center)
        .padding(.vertical, 48)
    }
}

struct AnimatedShape<Content : Shape> : View {
    let shape: Content
    let color: Color
    let lineCape: CGLineCap
    
    @State private var percentage: CGFloat = .zero

    var body: some View {
        shape
            .trim(from: .zero, to: percentage)
            .stroke(color, style: .init(lineWidth: 12, lineCap: lineCape))
            .animation(.easeOut)
            .onAppear {
                percentage = 1.0
            }
    }
}

struct CheckmarkView : View {
    var body: some View {
        AnimatedShape(shape: Checkmark(), color: .white, lineCape: .round)
    }
    
    struct Checkmark: Shape {
        func path(in rect: CGRect) -> Path {
            let width = rect.size.width
            let height = rect.size.height
            var path = Path()
            path.move(to: .init(x: 0.2 * width, y: 0.5 * height))
            path.addLine(to: .init(x: 0.4 * width, y: 0.75 * height))
            path.addQuadCurve(to: .init(x: 0.8 * width, y: 0.3 * height), control: .init(x: 0.5 * width, y: 0.45 * height))
            return path
        }
    }
}

struct XmarkView : View {
    var body: some View {
        AnimatedShape(shape: Xmark(), color: .red, lineCape: .butt)
    }

    struct Xmark: Shape {
        func path(in rect: CGRect) -> Path {
            let width = rect.size.width
            let height = rect.size.height
            var path = Path()
            path.move(to: .init(x: 0.1 * width, y: 0.1 * height))
            path.addLine(to: .init(x: 0.85 * width, y: 0.9 * height))
            path.move(to: .init(x: 0.85 * width, y: 0.1 * height))
            path.addQuadCurve(to: .init(x: 0.1 * width, y: 0.9 * height), control: .init(x: 0.4 * width, y: 0.4 * height))
            return path
        }
    }
}

struct GoNoGoStepView_Previews: PreviewProvider {
    static var previews: some View {
        GoNoGoStepView(StepState(step: example))
            .environmentObject(PagedNavigationViewModel(pageCount: 4, currentIndex: 2))
            .environmentObject(AssessmentState(AssessmentObject(previewStep: example)))
    }
}

fileprivate let example = GoNoGoStepObject()

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
