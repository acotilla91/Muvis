//
//  ActorItem.swift
//  Muvis
//
//  Created by Alejandro Cotilla on 3/2/19.
//  Copyright © 2019 Carolco LLC. All rights reserved.
//

import UIKit

class ActorItem: NSObject {
    var fullyDetailed = false
    var tmdbId: String = ""
    var name: String = ""
    var profilePath: String = ""
    var biography: String = ""
    var relatedMovies: [MediaItem] = []
    
    lazy var shortBiography: String = {
        var shortBiography = ""
        
        // Get first 2 sentences
        var addedSentences = 0
        biography.enumerateSubstrings(in: biography.startIndex..<biography.endIndex, options: .bySentences) { (substring, substringRange, enclosingRange, stop) in
            if let sentence = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !sentence.isEmpty {
                shortBiography = sentence
                addedSentences += 1
                if addedSentences == 2 {
                    stop = true
                }
            }
        }
        return shortBiography
    }()
}
