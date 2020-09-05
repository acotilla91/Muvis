//
//  UserScoreView.swift
//  Muvis
//
//  Created by Alejandro Cotilla on 2/18/19.
//  Copyright © 2019 Carolco LLC. All rights reserved.
//

import UIKit
import UICircularProgressRing
import ACAnimator

extension UICircularProgressRing {
    // https://stackoverflow.com/a/25943399/1792699
    private func redToGreenColor(greenAmount: CGFloat) -> UIColor {
        // the hues between red and green go from 0…1/3, so we can just divide percentageGreen by 3 to mix between them
        return UIColor(hue: greenAmount / 3.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
    }
    
    func animateToValue(_ targetValue: CGFloat) {
        let animator = ACAnimator(duration: 1.5, easeFunction: .sineOut, animation: { [weak self] (fraction, _, _) in
            guard let strongSelf = self else { return }
            let newValue = targetValue * CGFloat(fraction)
            strongSelf.innerRingColor = strongSelf.redToGreenColor(greenAmount: newValue / 100.0)
            strongSelf.value = newValue
        })
        animator.start()
    }
    
    func setColorfulValue(_ targetValue: CGFloat) {
        innerRingColor = redToGreenColor(greenAmount: targetValue / 100.0)
        value = targetValue
    }
}
