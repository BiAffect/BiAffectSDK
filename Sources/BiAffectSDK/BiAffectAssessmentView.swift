//
//  BiAffectAssessmentView.swift
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
    @State var didResignActive = false
    
    public init(_ assessmentState: AssessmentState) {
        self.assessmentState = assessmentState
    }
    
    public var body: some View {
        AssessmentWrapperView<StepView>(assessmentState, viewModel: viewModel)
    }
    
    struct StepView : View, StepFactoryView {
        @EnvironmentObject var pagedNavigation: PagedNavigationViewModel
        @ObservedObject var state: StepState
        
        init(_ state: StepState) {
            self.state = state
        }
        
        var body: some View {
            stepView()
                .onAppear {
                    // Always hide the progress view
                    pagedNavigation.progressHidden = true
                }
        }
        
        @ViewBuilder
        private func stepView() -> some View {
            if let step = state.step as? CompletionStep {
                CompletionStepView(step)
            }
            else if state.step is GoNoGoStepObject {
                GoNoGoStepView(state)
                    .modifier(AppBackgroundListener())
            }
            else if state.step is TrailmakingStepObject {
                TrailmakingStepView(state)
                    .modifier(AppBackgroundListener())
            }
            else if state.step is CountdownStep {
                CountdownStepView(state)
            }
            else if let nodeState = state as? ContentNodeState {
                InstructionStepView(nodeState, alignment: .center)
                    .surveyTintColor(.sageBlack)
            }
            else {
                VStack {
                    Spacer()
                    Text(state.id)
                    Spacer()
                    SurveyNavigationView()
                }
            }
        }
    }
}

struct AppBackgroundListener : ViewModifier {
    @EnvironmentObject var assessmentState: AssessmentState
    @State var didResignActive = false

    func body(content: Content) -> some View {
        content
            .alert(isPresented: $didResignActive) {
                Alert(title: Text("This activity has been interrupted and cannot continue.", bundle: .module),
                      message: nil,
                      dismissButton: .default(Text("OK", bundle: .module), action: {
                    assessmentState.status = .continueLater
                }))
            }
        #if os(iOS)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                didResignActive = true
            }
        #endif
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
        Group {
            BiAffectAssessmentPreview(.goNoGo)
            BiAffectAssessmentPreview(.goNoGo)
                .preferredColorScheme(.dark)
        }
    }
}

extension AssessmentObject {
    convenience init(previewStep: Step) {
        self.init(identifier: previewStep.identifier, children: [previewStep])
    }
}
