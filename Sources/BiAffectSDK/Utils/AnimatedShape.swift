//
//  AnimatedShape.swift
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
