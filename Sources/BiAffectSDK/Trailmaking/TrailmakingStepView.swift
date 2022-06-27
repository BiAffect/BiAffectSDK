//
//  TrailmakingStepView.swift
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

// TODO: syoung 06/24/2022 There is no "taking too long" exit. Should there be?
// TODO: syoung 06/24/2022 Is it intensional to not show any response after selecting first button?

struct TrailmakingStepView: View {
    @EnvironmentObject var assessmentState: AssessmentState
    @EnvironmentObject var pagedNavigation: PagedNavigationViewModel
    @ObservedObject var nodeState: StepState
    @StateObject var viewModel: ViewModel = .init()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(_ nodeState: StepState) {
        self.nodeState = nodeState
    }
    
    let runtimeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            StepHeaderTitleView {
                Text(viewModel.runtime, formatter: runtimeFormatter)
                    .font(.system(size: 18, design: .monospaced))
                    .foregroundColor(.textForeground)
            }
            GeometryReader { geometry in
                ZStack {
                    TrailmakingPath(points: viewModel.points, currentIndex: $viewModel.currentIndex)
                        .stroke(Color.accentColor, style: .init(lineWidth: 6, lineJoin: .round))
                    ForEach(viewModel.points) { point in
                        Button(action: { viewModel.onTap(at: point.index) }) {
                            Text(point.label)
                        }
                        .buttonStyle(
                            TrailmakingButtonStyle(index: point.index,
                                                   currentIndex: $viewModel.currentIndex,
                                                   lastIncorrectTap: $viewModel.lastIncorrectTap))
                        .position(x: geometry.size.width * point.x,
                                  y: geometry.size.height * point.y)
                    }
                }
                .accentColor(.blue)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding()
        }
        .onAppear {
            viewModel.onAppear(nodeState)
        }
        .onDisappear {
            timer.upstream.connect().cancel()
        }
        .onChange(of: viewModel.testState) { newValue in
            if newValue >= .finished {
                pagedNavigation.goForward()
            }
        }
        .onChange(of: assessmentState.showingPauseActions) { newValue in
            viewModel.paused = newValue
        }
        .onReceive(timer) { _ in
            viewModel.onTimerUpdated()
        }
    }
    
    @MainActor
    class ViewModel : ObservableObject {
        @Published var points: [TrailmakingPoint] = TrailmakingPoint.generate()
        @Published var runtime: DateComponents = .init()
        @Published var lastIncorrectTap: Int = -1
        @Published var numberOfErrors: Int = 0
        @Published var testState: TestState = .idle
        @Published var currentIndex: Int = 0
        
        @Published var paused: Bool = false {
            didSet {
                if paused {
                    pauseUptime = ProcessInfo.processInfo.systemUptime
                }
                else if let uptime = pauseUptime, startUptime > 0 {
                    let timestamp = ProcessInfo.processInfo.systemUptime
                    pauseInterval += (timestamp - uptime)
                    pauseUptime = nil
                    result?.pauseInterval = pauseInterval
                }
            }
        }
        
        enum TestState : Int, Comparable {
            case idle, running, stopping, finished, error
        }
        
        var result: TrailmakingResultObject!
        var startUptime: TimeInterval = 0
        var pauseInterval: TimeInterval = 0
        var pauseUptime: TimeInterval?
        var stopUptime: TimeInterval?
        
        func onAppear(_ nodeState: StepState) {
            guard let result = nodeState.result as? TrailmakingResultObject
            else {
                testState = .error
                assertionFailure("Expected result is not in the node state.")
                return
            }
            
            self.result = result
            testState = .running
            reset()
        }
        
        func reset() {
            
            // reset the result
            result.startDateTime = Date()
            result.points = points
            result.numberOfErrors = nil
            result.responses = []
            result.pauseInterval = nil
            
            // reset the test
            startUptime = ProcessInfo.processInfo.systemUptime
            pauseInterval = 0
            pauseUptime = nil
            runtime = .init()
            lastIncorrectTap = -1
            numberOfErrors = 0
            currentIndex = 0
        }
        
        func onTap(at index: Int) {
            guard testState == .running else { return }
            
            let now = ProcessInfo.processInfo.systemUptime
            let timestamp = now - startUptime
            let correct = index == currentIndex
            result.responses?.append(.init(timestamp: timestamp, index: index, incorrect: !correct))
            
            if correct {
                currentIndex += 1
                lastIncorrectTap = -1
                if currentIndex >= points.count {
                    result.runtime = timestamp - pauseInterval
                    stopUptime = now
                    testState = .stopping
                }
            }
            else {
                numberOfErrors += 1
                result.numberOfErrors = numberOfErrors
                lastIncorrectTap = index
            }
        }
        
        func onTimerUpdated() {
            
            // Check if stopping and exit early if final result has been shown
            if testState == .stopping,
               let stopUptime = stopUptime,
               ProcessInfo.processInfo.systemUptime - stopUptime >= 2.0 {
                testState = .finished
            }
            
            // Otherwise, do nothing unless running and not paused
            guard !paused, testState == .running else { return }
            let duration = ProcessInfo.processInfo.systemUptime - startUptime - pauseInterval
            runtime.second = Int(duration)
        }
    }
}

fileprivate struct TrailmakingPath : Shape {
    let points: [TrailmakingPoint]
    @Binding var currentIndex: Int
    
    func path(in rect: CGRect) -> Path {
        let width = rect.size.width
        let height = rect.size.height
        var path = Path()
        path.move(to: .init(x: points[0].x * width, y: points[0].y * height))
        if currentIndex > 1 {
            for ii in 1..<min(currentIndex, points.count) {
                path.addLine(to: .init(x: points[ii].x * width, y: points[ii].y * height))
            }
        }
        return path
    }
}

fileprivate struct TrailmakingButtonStyle : ButtonStyle {
    let index : Int
    @Binding var currentIndex: Int
    @Binding var lastIncorrectTap: Int

    let size: CGFloat = 44
    
    @ViewBuilder func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.latoFont(fixedSize: 18, weight: .bold))
            .foregroundColor(textForeground(configuration))
            .frame(width: size, height: size, alignment: .center)
            .background(
                ZStack {
                    Circle()
                        .fill(background(configuration))
                    Circle()
                        .stroke(borderColor(configuration), style: .init(lineWidth: 2))
                }
            )
    }
    
    func textForeground(_ configuration: Self.Configuration) -> Color {
        configuration.isPressed ? .white : unselectedStrokeColor()
    }
    
    func borderColor(_ configuration: Self.Configuration) -> Color {
        configuration.isPressed ? pressedColor() : unselectedStrokeColor()
    }
    
    func background(_ configuration: Self.Configuration) -> Color {
        configuration.isPressed ? pressedColor() : .white
    }
    
    func unselectedStrokeColor() -> Color {
        (index == lastIncorrectTap ? .red : .accentColor)
    }
    
    func pressedColor() -> Color {
        index == currentIndex ? .accentColor : .red
    }
}

struct TrailmakingStepView_Previews: PreviewProvider {
    static var previews: some View {
        TrailmakingStepView(StepState(step: example))
            .environmentObject(PagedNavigationViewModel(pageCount: 4, currentIndex: 2))
            .environmentObject(AssessmentState(AssessmentObject(previewStep: example)))
    }
}

fileprivate let example = TrailmakingStepObject()

