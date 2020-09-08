//
//  FeaturedCellView.swift
//  Muvis
//
//  Created by Alejandro Cotilla on 2/16/19.
//  Copyright © 2019 Carolco LLC. All rights reserved.
//

import UIKit
import UICircularProgressRing

class FeaturedCellView: UICollectionViewCell, NameDescribable, MediaCellView {

    @IBOutlet weak var imageView: ShadowImageView!
    
    @IBOutlet weak var userScoreView: UICircularProgressRing! {
        didSet {
            userScoreView.font = userScoreView.font.withSize(13)
            userScoreView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            userScoreView.layer.cornerRadius = userScoreView.frame.width / 2.0
            userScoreView.layer.masksToBounds = true
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!
}

