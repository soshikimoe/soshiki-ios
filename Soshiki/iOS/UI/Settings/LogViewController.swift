//
//  LogViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 5/8/23.
//

import UIKit

class LogViewController: BaseViewController {
    let textView: UITextView

    override init() {
        self.textView = UITextView()

        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = self.textView
    }

    override func configureViews() {
        self.navigationItem.largeTitleDisplayMode = .never

        let style = NSMutableParagraphStyle()
        style.paragraphSpacing = 10
        self.textView.attributedText = NSAttributedString(
            string: LogManager.shared.getFormattedLogs().joined(separator: "\n"),
            attributes: [
                .paragraphStyle: style,
                .foregroundColor: UIColor.label,
                .font: UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
            ]
        )
        self.textView.isEditable = false
    }
}
