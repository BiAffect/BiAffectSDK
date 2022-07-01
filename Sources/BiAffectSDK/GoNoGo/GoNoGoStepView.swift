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
import MobilePassiveData

#if canImport(AudioToolbox)
import AudioToolbox
func vibrateDevice() {
    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
}
#else
func vibrateDevice() { }
#endif

extension SoundFile {
    static let success = SoundFile(name: "sms-received5")
    static let failure = SoundFile(name: "jbl_cancel")
}

extension Font {
    static let instruction: Font = .latoFont(24, relativeTo: .title, weight: .regular)
    static let detail: Font = .latoFont(16, relativeTo: .footnote, weight: .regular)
}

// TODO: syoung 06/24/2022 There is no "failed too many times" exit. Should there be?

struct GoNoGoStepView: View {
    @EnvironmentObject var assessmentState: AssessmentState
    @EnvironmentObject var pagedNavigation: PagedNavigationViewModel
    @ObservedObject var nodeState: StepState
    @StateObject var viewModel: ViewModel = .init()
    let soundPlayer: AudioFileSoundPlayer = .init()
    
    init(_ nodeState: StepState) {
        self.nodeState = nodeState
    }
    
    var body: some View {
        VStack {
            StepHeaderView(nodeState)
            Spacer()
            instructions()
            stimulus()
            Spacer()
        }
        .onAppear {
            viewModel.onAppear(nodeState, assessmentState)
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onReceive(deviceShaked) { timestamp in
            viewModel.onDeviceShaked(timestamp)
        }
        .onChange(of: viewModel.testState) { newValue in
            if newValue >= .finished {
                pagedNavigation.goForward()
            }
        }
        .onChange(of: assessmentState.showingPauseActions) { newValue in
            viewModel.paused = newValue
        }
        .onReceive(viewModel.shakeSensor.errorNotification) { error in
            viewModel.onMotionRecorderError(error)
        }
    }

    @State var contentHeight: CGFloat = 0
    
    @ViewBuilder
    func instructions() -> some View {
        // Instructions and response - these are wrapped in a scrollview in case
        // the participant has extra large accessibility text turned on.
        ScrollView {
            VStack(alignment: .center, spacing: 24) {
                Text(viewModel.instructions)
                    .font(.instruction)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Attempt \(viewModel.attemptCount) of \(viewModel.maxSuccessCount)", bundle: .module)
                    HStack {
                        Text("Last reaction time:")
                        Text("\(viewModel.lastReactionTime ?? 0, specifier: "%.2f") seconds", bundle: .module)
                            .opacity(viewModel.lastReactionTime == nil ? 0 : 1)
                    }
                    HStack {
                        Text("Errors:", bundle: .module)
                        Text("\(viewModel.errorCount)")
                            .opacity(viewModel.errorCount > 0 ? 1 : 0)
                    }
                }
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
            // The circle is shown/hidden using opacity b/c its more performant
            Circle()
                .fill(viewModel.go ? .blue : .green)
                .opacity(viewModel.showingDot ? 1 : 0)
            // The response is added/removed b/c the animation of drawing the
            // checkmark or X is simplier.
            if viewModel.showingResponse {
                if viewModel.correct {
                    CheckmarkView()
                        .onAppear {
                            soundPlayer.playSound(.success)
                        }
                }
                else {
                    XmarkView()
                        .onAppear {
                            if viewModel.didTimeout {
                                soundPlayer.playSound(.failure)
                            }
                            else {
                                vibrateDevice()
                            }
                        }
                }
            }
        }
        .frame(width: 128, height: 128, alignment: .center)
        .padding(.vertical, 48)
    }
    
    @MainActor
    class ViewModel : ObservableObject {
        @Published var instructions: String = "Hello, World"
        @Published var attemptCount: Int = 1
        @Published var maxSuccessCount: Int = 9
        @Published var errorCount: Int = 0
        @Published var lastReactionTime: SecondDuration?
        @Published var go: Bool = false
        @Published var correct: Bool = false
        @Published var didTimeout: Bool = false
        @Published var testState: TestState = .idle
        @Published var showingDot: Bool = false
        @Published var showingResponse: Bool = false

        enum TestState : Int, Comparable {
            case idle, running, finished, error
        }
        
        @Published var paused: Bool = false {
            didSet {
                guard shakeSensor.status == .running else { return }
                if paused {
                    // pause the clock and stop sampling
                    shakeSensor.pause()
                }
                else {
                    reset()
                }
            }
        }
        
        var assessmentResult: AssessmentResult!
        var result: GoNoGoResultObject!
        var step: GoNoGoStepObject!
        var successCount: Int = 0
        var isVisible: Bool = false
        var waitTask: Task<Void, Never>?
        let shakeSensor: ShakeMotionSensor = .init()
        
        func onAppear(_ nodeState: StepState, _ assessmentState: AssessmentState) {
            guard let result = nodeState.result as? GoNoGoResultObject,
                  let step = nodeState.step as? GoNoGoStepObject
            else {
                testState = .error
                assertionFailure("Expected step and result are not in the node state.")
                return
            }
            guard !isVisible else { return }
            isVisible = true
            
            self.assessmentResult = assessmentState.assessmentResult
            self.result = result
            self.step = step
            self.instructions = step.detail
            self.maxSuccessCount = step.numberOfAttempts
            self.shakeSensor.thresholdAcceleration = step.thresholdAcceleration
            result.startUptime = shakeSensor.clock.startUptime
            assessmentState.outputDirectory = shakeSensor.outputDirectory
            
            Task {
                do {
                    try await shakeSensor.start()
                    reset()
                } catch {
                    result.motionError = .init(identifier: "motion", error: error)
                    testState = .error
                }
            }
        }
        
        func onDisappear() {
            guard isVisible else { return }
            isVisible = false
            waitTask?.cancel()
            shakeSensor.cancel()
        }
        
        func onDeviceShaked(_ timestamp: SystemUptime) {
            Task {
                let uptime = await shakeSensor.clock.relativeUptime(to: timestamp)
                guard isVisible, !showingResponse, !paused else { return }
                didFinishAttempt(uptime)
            }
        }
        
        func onMotionRecorderError(_ error: Error) {
            guard isVisible, testState == .running else { return }
            result.motionError = .init(identifier: "motion", error: error)
            testState = .error
        }
        
        func reset() {
            guard isVisible, !paused, shakeSensor.status == .running else { return }
            waitTask?.cancel()
            
            shakeSensor.reset()
            testState = .running
            showingDot = false
            showingResponse = false
            go = calculateNextGo()
            attemptCount = min(max(1, successCount + 1), maxSuccessCount)
            
            let stimulusDelay = calculateStimulusDelay()
            
            waitTask = Task {
                guard await Task.wait(seconds: stimulusDelay) else { return }
                showStimulus()
            }
        }
        
        func showStimulus() {
            shakeSensor.stimulusUptime = SystemClock.uptime()
            shakeSensor.dotType = go ? .blue : .green
            showingDot = true
            waitTask = Task {
                guard await Task.wait(seconds: step.timeout) else { return }
                didFinishAttempt()
            }
        }
        
        func didFinishAttempt(_ thresholdUptime: TimeInterval? = nil) {
            guard isVisible, !showingResponse, !paused else { return }
            waitTask?.cancel()
            
            // Determine response
            didTimeout = (thresholdUptime == nil)
            correct = showingDot && (go ? !didTimeout : didTimeout)
            if correct {
                successCount += 1
            }
            else {
                errorCount += 1
            }
            let startUptime = shakeSensor.stimulusUptime ?? 0
            let timeToThreshold = thresholdUptime.map { correct ? $0 - startUptime : 0 } ?? 0
            
            // Update display
            shakeSensor.dotType = .result
            showingDot = correct
            showingResponse = true
            if go && correct {
                lastReactionTime = timeToThreshold
            }

            // Add response to result
            result.responses.append(.init(stepPath: shakeSensor.currentStepPath,
                                          timestamp: startUptime,
                                          resetTimestamp: shakeSensor.resetUptime,
                                          timeToThreshold: timeToThreshold,
                                          go: go,
                                          incorrect: !correct,
                                          samples: shakeSensor.processSamples()))

            // Show response for 2.5 seconds before continuing
            waitTask = Task {
                guard await Task.wait(seconds: 2.5) else { return }
                startNext()
            }
        }
        
        func startNext() {
            if successCount >= maxSuccessCount {
                Task {
                    let motionResult = try await shakeSensor.stop()
                    self.assessmentResult.asyncResults = [motionResult]
                    testState = .finished
                }
            }
            else {
                reset()
            }
        }
        
        func calculateStimulusDelay() -> TimeInterval {
            TimeInterval.random(in: step.minimumStimulusInterval...step.maximumStimulusInterval)
        }
        
        func calculateNextGo() -> Bool {
            // Note: Calulation is done using the algorithm used in ResearchKit 1.0
            
            let responses = result.responses
            let total = responses.count
            
            // Never allow more than 2 no go in a row
            if total >= 2,
               !responses[total-1].go,
               !responses[total-2].go {
                return true
            }
            
            // Always include at least one no-go so if this is the last attempt
            // check that there has been at least one no-go response.
            if successCount == maxSuccessCount - 1,
               !responses.contains(where: { !$0.go }) {
                return false
            }
            
            // Otherwise, ~2/3 of the time, return a "go" stimulus
            return drand48() < 0.667
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

