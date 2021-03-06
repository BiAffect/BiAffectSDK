//
//  ContentView.swift
//  BiAffectPreview
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
import BridgeClientUI
import Research
import AssessmentModel
import AssessmentModelUI
import BiAffectSDK

public struct ContentView: View {
    @EnvironmentObject var bridgeManager: SingleStudyAppManager
    @StateObject var todayViewModel: TodayTimelineViewModel = .init()
    
    public init() {}
    
    public var body: some View {
        switch bridgeManager.appState {
        case .launching:
            LaunchView()
        case .login:
            LoginView()
        case .onboarding:
            OnboardingView()
                .onAppear {
                    // Start fetching records and schedules on login
                    todayViewModel.onAppear(bridgeManager: bridgeManager)
                }
        case .main:
            MainView()
                .environmentObject(todayViewModel)
                //.assessmentInfoMap(.init(extensions: MTBIdentifier.allCases))
                .fullScreenCover(isPresented: $todayViewModel.isPresentingAssessment) {
                    assessmentView()
                }
        }
    }
    
    @ViewBuilder
    func assessmentView() -> some View {
        switch todayViewModel.selectedAssessmentViewType {
        case .survey(let info):
            SurveyView<AssessmentView>(info, handler: todayViewModel)
        case .biaffect(let info):
            SurveyView<BiAffectAssessmentView>(info, handler: todayViewModel)
        default:
            emptyAssessment()
        }
    }
    
    @ViewBuilder
    func emptyAssessment() -> some View {
        VStack {
            Text("This assessment is not supported by this app version")
            Button("Dismiss", action: { todayViewModel.isPresentingAssessment = false })
        }
    }
}

enum AssessmentViewType {
    case survey(AssessmentScheduleInfo)
    case biaffect(AssessmentScheduleInfo)
    case empty
}

extension TodayTimelineViewModel {
    
    var selectedAssessmentViewType : AssessmentViewType {
        guard let info = selectedAssessment else { return .empty }
        if let _ = BiAffectIdentifier(rawValue: info.assessmentIdentifier) {
            return .biaffect(info)
        }
        else {
            return .survey(info)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .environmentObject(SingleStudyAppManager(appId: kPreviewStudyId))
        }
    }
}
