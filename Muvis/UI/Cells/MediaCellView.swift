//
//  MediaCellView.swift
//  Muvis
//
//  Created by Alejandro Cotilla on 2/16/19.
//  Copyright © 2019 Carolco LLC. All rights reserved.
//

import UIKit
import Nuke

// Using a workaround to overcome the compiler error: "Protocol "<protocol>" can only be used as a generic constraint because it has Self or associated type requirements." for protocols using associated types.
// Workaround based on: https://stackoverflow.com/a/47231125/1792699

protocol TypeErasedMediaCellView {
    var typeErasedImageView: ImageDisplayingView! { get }
}

protocol MediaCellView: TypeErasedMediaCellView {
    associatedtype MediaCellViewImage: ImageDisplayingView
    var imageView: MediaCellViewImage! { get }
}

extension MediaCellView {
    var typeErasedImageView: ImageDisplayingView! { return imageView }
}
