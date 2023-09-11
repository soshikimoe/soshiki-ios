//
//  CallbackMenuButton.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/12/23.
//

import UIKit

class CallbackMenuButton: UIButton {
    var onOpenMenu: (() -> Void)?
    var onCloseMenu: (() -> Void)?

    override func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        willDisplayMenuFor configuration: UIContextMenuConfiguration,
        animator: UIContextMenuInteractionAnimating?
    ) {
        super.contextMenuInteraction(interaction, willDisplayMenuFor: configuration, animator: animator)
        onOpenMenu?()
    }

    override func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        willEndFor configuration: UIContextMenuConfiguration,
        animator: UIContextMenuInteractionAnimating?
    ) {
        super.contextMenuInteraction(interaction, willEndFor: configuration, animator: animator)
        onCloseMenu?()
    }
}
