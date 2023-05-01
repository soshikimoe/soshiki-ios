//
//  NSAttributedString.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/9/23.
//

import UIKit

extension NSAttributedString {
    static func html(_ html: String, font: UIFont? = nil, color: UIColor? = nil) -> Self? {
        let font = font ?? .preferredFont(forTextStyle: .body)
        let modifiedHtml = String(
            format: """
<span style=\"font-family: '\(font.fontName)', '-apple-system', 'HelveticaNeue'; font-size: \(font.pointSize); color: \(color?.hex ?? "unset")\">
%@
</span>
""",
            html
        )
        guard let data = modifiedHtml.data(using: .utf8) else { return nil }
        return try? self.init(
            data: data,
            options: [ .documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue ],
            documentAttributes: nil
        )
    }
}
