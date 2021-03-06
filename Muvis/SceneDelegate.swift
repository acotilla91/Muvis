//
//  SceneDelegate.swift
//  Muvis
//
//  Created by Alejandro Cotilla on 9/5/20.
//  Copyright © 2020 Carolco LLC. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        // Force light theme
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .light
        }

        guard let _ = (scene as? UIWindowScene) else { return }
    }
}

