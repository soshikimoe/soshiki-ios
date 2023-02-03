//
//  MainViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/22/23.
//

import UIKit

class MainViewController: UITabBarController {
    init() {
        super.init(nibName: nil, bundle: nil)
        let libraryNavigationController = UINavigationController(rootViewController: LibraryViewController())
        libraryNavigationController.tabBarItem = UITabBarItem(title: "Library", image: UIImage(systemName: "folder.fill"), tag: 0)
        libraryNavigationController.navigationBar.prefersLargeTitles = true

        let browseNavigationController = UINavigationController(rootViewController: BrowseViewController())
        browseNavigationController.tabBarItem = UITabBarItem(title: "Browse", image: UIImage(systemName: "globe"), tag: 1)
        browseNavigationController.navigationBar.prefersLargeTitles = true

        let searchNavigationController = UINavigationController(rootViewController: SearchViewController())
        searchNavigationController.tabBarItem = UITabBarItem(title: "Search", image: UIImage(systemName: "magnifyingglass"), tag: 2)
        searchNavigationController.navigationBar.prefersLargeTitles = true

        let settingsNavigationController = UINavigationController(rootViewController: SettingsViewController())
        settingsNavigationController.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), tag: 3)
        settingsNavigationController.navigationBar.prefersLargeTitles = true

        viewControllers = [
            libraryNavigationController,
            browseNavigationController,
            searchNavigationController,
            settingsNavigationController
        ]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
