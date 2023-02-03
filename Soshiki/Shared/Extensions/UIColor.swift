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
        guard let components = self.cgColor.components, components.count >= 3 else {
            return nil
        }
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
    }
}
