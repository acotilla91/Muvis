//
//  MediaActionsView.swift
//  Muvis
//
//  Created by Alejandro Cotilla on 2/20/19.
//  Copyright © 2019 Carolco LLC. All rights reserved.
//

import UIKit

protocol MediaActionsViewDelegate: class {
    func actionsViewDidSelectPlayButton(_ actionsView: MediaActionsView)
    func actionsViewDidSelectAddButton(_ actionsView: MediaActionsView)
    func actionsViewDidSelectDownloadButton(_ actionsView: MediaActionsView)
}

class MediaActionsView: UIView {

    weak var delegate: MediaActionsViewDelegate?
    
    private static let titleLabelFont = UIFont(name: "Nunito-Black", size: 22)!
    private static let titleLabelTop: CGFloat = 110.0
    private static let titleLabelLeading: CGFloat = 67.0
    private static let titleLabelTrailing: CGFloat = 67.0

    static let playButtonSize: CGFloat = 74.0
    
    // MARK: - Outlets -

    @IBOutlet weak var playImageView: UIImageView!
    
    @IBOutlet private weak var playButton: UIButton! {
        didSet {
            playButton.layer.cornerRadius = playButton.frame.width / 2
            playButton.dropShadow(color: .black, radius: 6.0, opacity: 0.3, offset: .zero, grazingCornerRadius: true)
        }
    }
    
    @IBOutlet private weak var addButton: UIButton! {
        didSet {
            addButton.imageEdgeInsets = UIEdgeInsets(top: 9, left: 9, bottom: 9, right: 9)
        }
    }
    
    @IBOutlet private weak var downloadButton: UIButton! {
        didSet {
            downloadButton.imageEdgeInsets = UIEdgeInsets(top: 9, left: 9, bottom: 9, right: 9)
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.font = MediaActionsView.titleLabelFont
        }
    }
    
    @IBOutlet weak var titleLabelTopConstraint: NSLayoutConstraint! {
        didSet {
            titleLabelTopConstraint.constant = MediaActionsView.titleLabelTop
        }
    }
    
    @IBOutlet weak var titleLabelLeadingConstraint: NSLayoutConstraint! {
        didSet {
            titleLabelLeadingConstraint.constant = MediaActionsView.titleLabelLeading
        }
    }
    
    @IBOutlet weak var titleLabelTrailingConstraint: NSLayoutConstraint! {
        didSet {
            titleLabelTrailingConstraint.constant = MediaActionsView.titleLabelTrailing
        }
    }
    
    @IBOutlet weak var playButtonTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var playButtonWidthConstraint: NSLayoutConstraint! {
        didSet {
            playButtonWidthConstraint.constant = MediaActionsView.playButtonSize
        }
    }
    
    @IBOutlet weak var playButtonHeightConstraint: NSLayoutConstraint! {
        didSet {
            playButtonHeightConstraint.constant = MediaActionsView.playButtonSize
        }
    }
    
    class func cellHeightForTitle(_ title: String, width: CGFloat) -> CGFloat {
        let titleWidth = width - titleLabelLeading - titleLabelTrailing
        return title.height(withConstrainedWidth: titleWidth, font: MediaActionsView.titleLabelFont) + titleLabelTop
    }
    
    // MARK: - Actions -
    
    @IBAction func playButtonSelected(_ sender: Any) {
        delegate?.actionsViewDidSelectPlayButton(self)
    }
    
    @IBAction func addButtonSelected(_ sender: Any) {
        delegate?.actionsViewDidSelectAddButton(self)
    }
    
    @IBAction func downloadButtonSelected(_ sender: Any) {
        delegate?.actionsViewDidSelectDownloadButton(self)
    }
}
