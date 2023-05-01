//
//  UIColor.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/28/23.
//

import UIKit

// Adapted from https://medium.com/geekculture/using-appstorage-with-swiftui-colors-and-some-nskeyedarchiver-magic-a38038383c5e
extension UIColor {
    public static func from(rawValue: String) -> UIColor {
        guard let data = Data(base64Encoded: rawValue) else {
            return .black
        }

        do {
            return try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIColor ?? .black
        } catch {
            return .black
        }
    }

    public var rawValue: String {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false) as Data
            return data.base64EncodedString()
        } catch {
            return ""
        }
    }
}

extension UIColor {
    // Adapted from https://blog.eidinger.info/from-hex-to-color-and-back-in-swiftui
    var hex: String? {
        guard let components = self.cgColor.components else {
            return nil
        }
        if components.count >= 3 {
            let r = Float(components[0])
            let g = Float(components[1])
            let b = Float(components[2])
            var a = Float(1)

            if components.count >= 4 {
                a = Float(components[3])
            }

            if a != Float(1) {
                return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
            } else {
                return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
            }
        } else if components.count >= 1 {
            let r = Float(components[0])
            let g = Float(components[0])
            let b = Float(components[0])
            var a = Float(1)

            if components.count >= 2 {
                a = Float(components[1])
            }

            if a != Float(1) {
                return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
            } else {
                return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
            }
        } else {
            return nil
        }
    }
}

extension UIColor {
    static func random() -> UIColor {
        UIColor(red: CGFloat.random(in: 0...1), green: CGFloat.random(in: 0...1), blue: CGFloat.random(in: 0...1), alpha: 1)
    }

    func contrastingFontColor() -> UIColor? {
        if let components = self.cgColor.components, components.count >= 3 {
            return (components[0] * 76.544 + components[1] * 150.272 + components[2] * 29.184) > 150 ? .black : .white
        } else {
            return nil
        }
    }
}
