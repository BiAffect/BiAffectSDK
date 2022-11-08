//
//  TrailmakingStepView.swift
//

import SwiftUI
import AssessmentModel
import AssessmentModelUI
import SharedMobileUI
import MobilePassiveData

#if canImport(AudioToolbox)
import AudioToolbox
fileprivate func vibrateDevice() {
    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
}
#else
fileprivate func vibrateDevice() {}
#endif

fileprivate let kTimeoutMinutes = 2

struct TrailmakingStepView: View {
    @EnvironmentObject var assessmentState: AssessmentState
    @EnvironmentObject var pagedNavigation: PagedNavigationViewModel
    @ObservedObject var nodeState: StepState
    @StateObject var viewModel: ViewModel = .init()
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
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
            viewModel.isPaused = newValue
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
        @Published var isPaused: Bool = false {
            didSet {
                guard testState == .running else { return }
                if isPaused {
                    clock.pause()
                }
                else {
                    clock.resume()
                }
            }
        }
        
        var clock: SimpleClock = .init()
        var timeoutCounter: Int = 0
        var lastActionTimestamp: SecondDuration = 0
        
        enum TestState : Int, Comparable {
            case idle, running, stopping, finished, error, timedOut
        }
        
        var result: TrailmakingResultObject!
        
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
            
            // reset the test
            clock.reset()
            timeoutCounter = 0
            lastActionTimestamp = 0
            runtime = .init()
            lastIncorrectTap = -1
            numberOfErrors = 0
            currentIndex = 0
        }
        
        func onTap(at index: Int) {
            guard testState == .running else { return }
            
            let timestamp = clock.runningDuration()
            let correct = index == currentIndex
            result.responses?.append(.init(timestamp: timestamp, index: index, incorrect: !correct))
            lastActionTimestamp = timestamp
            timeoutCounter = 0
            
            if correct {
                currentIndex += 1
                lastIncorrectTap = -1
                if currentIndex >= points.count {
                    result.runtime = timestamp
                    result.pauseInterval = clock.pauseCumulation
                    testState = .stopping
                    clock.stop()
                }
            }
            else {
                numberOfErrors += 1
                result.numberOfErrors = numberOfErrors
                lastIncorrectTap = index
            }
        }
        
        func onTimerUpdated() {
            
            // Check if stopping and update state if the final result has been displayed for at least 2 seconds
            if testState == .stopping, clock.stoppedDuration() >= 2.0 {
                testState = .finished
            }
            
            // Update the runtime
            else if !clock.isPaused, testState == .running {
                let timestamp = clock.runningDuration()
                runtime.second = Int(timestamp)
                if timestamp - lastActionTimestamp > 60 {
                    timeoutCounter += 1
                    lastActionTimestamp = timestamp
                    vibrateDevice()
                    if timeoutCounter >= kTimeoutMinutes {
                        result.timedOut = true
                        testState = .timedOut
                    }
                }
            }
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

