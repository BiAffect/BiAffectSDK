//
//  AnimatedShape.swift
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
