//
//  ViewController.swift
//  Muvis
//
//  Created by Alejandro Cotilla on 9/5/20.
//  Copyright © 2020 Carolco LLC. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class ViewController: UIViewController {
    
    private var activityIndicator: NVActivityIndicatorView!
    
    private var mediaCategories: [MediaCategory] = []
    
    // MARK: - UI Setup -

    func setupActivityIndicator() {
        let indicatorSize: CGFloat = 60.0
        let indicatorOrigin = CGPoint(x: UIScreen.main.bounds.width/2 - indicatorSize/2, y: UIScreen.main.bounds.height/2 - indicatorSize/2)
        let indicatorFrame = CGRect(x: indicatorOrigin.x, y: indicatorOrigin.y, width: indicatorSize, height: indicatorSize)
        activityIndicator = NVActivityIndicatorView(frame: indicatorFrame, type: .circleStrokeSpin, color: UIColor(hex: "#434446"), padding: 8.0)
        view.addSubview(activityIndicator)
    }

    // MARK: - View Cycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide "Back" label
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        setupActivityIndicator()
        loadContent()
    }

    // MARK: - API Communication -

    private func loadContent() {
        activityIndicator.startAnimating()
        
        TMDbAPIService.shared.requestMediaCategories { (categories) in
            self.mediaCategories = categories

            // TODO: Load collection view with requested categories
            
            self.activityIndicator.stopAnimating()
        }
    }
}

