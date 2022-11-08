//
//  ContentView.swift
//  BiAffectViewBuilder
//

import SwiftUI
import AssessmentModelUI

struct ContentView: View {
    @StateObject var viewModel: ViewModel = .init()
    
    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(BiAffectIdentifier.allCases, id: \.rawValue) { name in
                Button(name.rawValue) {
                    viewModel.current = .init(try! name.instantiateAssessmentState())
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.isPresented) {
            AssessmentListener(viewModel)
        }
    }
    
    class ViewModel : ObservableObject {
        @Published var isPresented: Bool = false
        var current: AssessmentState? {
            didSet {
                isPresented = (current != nil)
            }
        }
    }
    
    struct AssessmentListener : View {
        @ObservedObject var viewModel: ViewModel
        @ObservedObject var state: AssessmentState
        
        init(_ viewModel: ViewModel) {
            self.viewModel = viewModel
            self.state = viewModel.current!
        }
        
        var body: some View {
            BiAffectAssessmentView(state)
                .onChange(of: state.status) { newValue in
                    print("assessment status = \(newValue)")
                    
                    // In a real use-case this is where you might save and upload data
                    if newValue == .readyToSave {
                        do {
                            let data = try state.result.jsonEncodedData()
                            let output = String(data: data, encoding: .utf8)!
                            print("assessment result = \n\(output)\n")
                        }
                        catch {
                            assertionFailure("Failed to encode result: \(error)")
                        }
                    }
                    
                    // Exit
                    guard newValue >= .finished else { return }
                    viewModel.isPresented = false
                    viewModel.current = nil
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
