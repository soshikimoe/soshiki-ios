//
//  UIResponder.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/29/23.
//
//  From https://github.com/SwiftUIX/SwiftUIX/blob/master/Sources/Intermodular/Extensions/UIKit/UIResponder++.swift
//

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)

import Swift
import UIKit

// swiftlint:disable force_cast
extension UIResponder {
    var globalFrame: CGRect? {
        guard let view = self as? UIView else {
            return nil
        }

        return view.superview?.convert(view.frame, to: nil)
    }
}

extension UIResponder {
    private static weak var _firstResponder: UIResponder?

    @available(macCatalystApplicationExtension, unavailable)
    @available(iOSApplicationExtension, unavailable)
    @available(tvOSApplicationExtension, unavailable)
    static var firstResponder: UIResponder? {
        _firstResponder = nil

        UIApplication.shared.sendAction(#selector(UIResponder.acquireFirstResponder(_:)), to: nil, from: nil, for: nil)

        return _firstResponder
    }

    @objc private func acquireFirstResponder(_ sender: Any) {
        UIResponder._firstResponder = self
    }
}

extension UIResponder {
    public func _nearestResponder<Responder: UIResponder>(ofKind kind: Responder.Type) -> Responder? {
        guard !isKind(of: kind) else {
            return (self as! Responder)
        }

        return next?._nearestResponder(ofKind: kind)
    }

    private func _furthestResponder<Responder: UIResponder>(ofKind kind: Responder.Type, default _default: Responder?) -> Responder? {
        next?._furthestResponder(ofKind: kind, default: self as? Responder) ?? _default
    }

    public func _furthestResponder<Responder: UIResponder>(ofKind kind: Responder.Type) -> Responder? {
        _furthestResponder(ofKind: kind, default: nil)
    }

    public func forEach<Responder: UIResponder>(ofKind kind: Responder.Type, recursive iterator: (Responder) throws -> Void) rethrows {
        if isKind(of: kind) {
            try iterator(self as! Responder)
        }

        try next?.forEach(ofKind: kind, recursive: iterator)
    }

    func _decomposeChildViewControllers() -> [UIViewController] {
        if let responder = self as? UINavigationController {
            return responder.children
        } else if let responder = self as? UISplitViewController {
            return responder.children
        } else {
            return []
        }
    }
}

extension UIResponder {
    @objc open var nearestViewController: UIViewController? {
        _nearestResponder(ofKind: UIViewController.self)
    }

    @objc open var furthestViewController: UIViewController? {
        _furthestResponder(ofKind: UIViewController.self)
    }

    @objc open var nearestNavigationController: UINavigationController? {
        _nearestResponder(ofKind: UINavigationController.self)
    }

    @objc open var furthestNavigationController: UINavigationController? {
        _furthestResponder(ofKind: UINavigationController.self)
    }
}

#endif
