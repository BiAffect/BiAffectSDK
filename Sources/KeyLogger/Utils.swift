//
//  Utils.swift
//  BiAffectKeyboard
//
//  Created by Andrea Piscitello on 01/11/16.
//

import SwiftUI

public class Utils {
    public static func distance(_ a: CGPoint, b: CGPoint) -> CGFloat {
        return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))
    }
    
    public static func getCenter(_ size: CGSize) -> CGPoint {
        return CGPoint(x: size.width/2, y: size.height/2)
    }
}
