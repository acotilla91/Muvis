//
//  YouTubeItem.swift
//  Muvis
//
//  Created by Alejandro Cotilla on 3/1/19.
//  Copyright © 2019 Carolco LLC. All rights reserved.
//

import UIKit

class YouTubeItem: NSObject {

    var tmdbId: String = ""
    var youtubeId: String = ""
    var title: String = ""
    var type: String = ""
    
    // Thumbnail path construction based on: https://stackoverflow.com/a/2068371/1792699
    lazy var thumbnailPathHigh: String = {
        return "https://img.youtube.com/vi/\(youtubeId)/maxresdefault.jpg"
    }()
    
    lazy var thumbnailPathMedium: String = {
        return "https://i.ytimg.com/vi/\(youtubeId)/mqdefault.jpg"
    }()
}
