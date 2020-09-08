//
//  MediaDescriptionCellView.swift
//  Muvis
//
//  Created by Alejandro Cotilla on 2/20/19.
//  Copyright © 2019 Carolco LLC. All rights reserved.
//

import UIKit

class MediaDescriptionCellView: UICollectionViewCell, NameDescribable {

    private static let overviewLabelFont = UIFont(name: "Nunito-Regular", size: 17)!
    private static let overviewLabelTop: CGFloat = 10.0
    private static let overviewLabelTrailing: CGFloat = 18.0
    private static let overviewLabelLeading: CGFloat = 18.0

    @IBOutlet weak var overviewLabel: UILabel! {
        didSet {
            overviewLabel.font = MediaDescriptionCellView.overviewLabelFont
        }
    }
    
    @IBOutlet weak var overviewLabelTopConstraint: NSLayoutConstraint! {
        didSet {
            overviewLabelTopConstraint.constant = MediaDescriptionCellView.overviewLabelTop
        }
    }
    
    @IBOutlet weak var overviewLabelTrailingConstraint: NSLayoutConstraint! {
        didSet {
            overviewLabelTrailingConstraint.constant = MediaDescriptionCellView.overviewLabelTrailing
        }
    }
    @IBOutlet weak var overviewLabelLeadingConstraint: NSLayoutConstraint! {
        didSet {
            overviewLabelLeadingConstraint.constant = MediaDescriptionCellView.overviewLabelLeading
        }
    }
    
    class func cellHeightForOverview(_ overview: String, width: CGFloat) -> CGFloat {
        let overviewWidth = width - overviewLabelLeading - overviewLabelTrailing
        return overview.height(withConstrainedWidth: overviewWidth, font: MediaDescriptionCellView.overviewLabelFont) + overviewLabelTop * 2.0
    }
    
}

