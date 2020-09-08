//
//  CircularCellView.swift
//  Muvis
//
//  Created by Alejandro Cotilla on 3/2/19.
//  Copyright © 2019 Carolco LLC. All rights reserved.
//

import UIKit

class CircularCellView: UICollectionViewCell, NameDescribable {

    static let imageHorizontalPadding: CGFloat = 20
    
    @IBOutlet weak var imageView: ShadowImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint! {
        didSet {
            imageViewLeadingConstraint.constant = CircularCellView.imageHorizontalPadding
        }
    }
    
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint! {
        didSet {
            imageViewTrailingConstraint.constant = 20
        }
    }
}
