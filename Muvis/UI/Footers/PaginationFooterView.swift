//
//  PaginationFooterView.swift
//  Muvis
//
//  Created by Alejandro Cotilla on 9/7/20.
//  Copyright © 2020 Carolco LLC. All rights reserved.
//

import UIKit

class PaginationFooterView: UICollectionReusableView, NameDescribable {
    var paginationView: ACPaginationView!
    
    func configurePaginationView(withNumberOfPages pagesCount: Int) {
        guard paginationView == nil else {
            return
        }
        
        paginationView = ACPaginationView(diameter: 7, innerSpacing: 5, count: pagesCount, normalColor: UIColor(white: 0.25, alpha: 0.3), highlightedColor: UIColor(white: 0.25, alpha: 1.0))
        self.addSubview(paginationView)

        // Center pagination view in footer view
        paginationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: paginationView!, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: paginationView!, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: paginationView!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: paginationView.frame.size.width),
            NSLayoutConstraint(item: paginationView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: paginationView.frame.size.height)
        ])
    }
}
