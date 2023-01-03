//
//  Color.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/19/22.
//
//  Adapted from https://www.hackingwithswift.com/example-code/uicolor/how-to-convert-a-hex-color-to-a-uicolor
//

import SwiftUI

extension Color {
    public init?(hex: String) {
        let r, g, b: CGFloat
        let start = hex.index(hex.startIndex, offsetBy: hex.hasPrefix("#") ? 1 : 0)
        let hexColor = String(hex[start...])

        if hexColor.count == 6 {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0

            if scanner.scanHexInt64(&hexNumber) {
                r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                b = CGFloat(hexNumber & 0x0000ff) / 255

                self.init(red: r, green: g, blue: b)
                return
            }
        }
        return nil
    }

    func contrastingFontColor() -> Color? {
        if let components = self.cgColor?.components, components.count >= 3 {
            return (components[0] * 76.544 + components[1] * 150.272 + components[2] * 29.184) > 150 ? .black : .white
        } else {
            return nil
        }
    }
}
