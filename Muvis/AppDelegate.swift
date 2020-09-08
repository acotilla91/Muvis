//
//  AppDelegate.swift
//  Muvis
//
//  Created by Alejandro Cotilla on 9/5/20.
//  Copyright © 2020 Carolco LLC. All rights reserved.
//

import UIKit
import ShowTime

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Enable 'ShowTime' (by commenting line below) if demo recording necessary
        ShowTime.enabled = .never
        
        return true
    }
}

