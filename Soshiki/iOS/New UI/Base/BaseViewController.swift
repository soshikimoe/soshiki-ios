//
//  BaseViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/6/23.
//

import UIKit

/**
 A view controller class which allows for observation of values, meant to be extended.
 */
class BaseViewController: UIViewController {
    var observers: [NSObjectProtocol] = []

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        applyConstraints()
    }

    /**
     Adds an observer to `NotificationCenter.default` which will be cleared on `deinit`.
     - Parameters:
     - key: The notification key.
     - block: The block that the notification is passed to.
     */
    func addObserver(_ key: String, block: @escaping (Notification) -> Void) {
        observers.append(NotificationCenter.default.addObserver(forName: .init(key), object: nil, queue: nil, using: block))
    }

    /// A function that is called during `viewDidLoad` intended to be overrided and handle any view setup.
    func configureViews() {}
    /// A function that is called during `viewDidLoad` intended to be overrided and handle any view constraints.
    func applyConstraints() {}
}
