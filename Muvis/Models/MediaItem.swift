//
//  MediaItem.swift
//  Muvis
//
//  Created by Alejandro Cotilla on 1/24/19.
//  Copyright © 2019 Carolco LLC. All rights reserved.
//

import UIKit
import Nuke

enum MediaItemImageType {
    case portrait
    case backdrop
}

class MediaItem: NSObject, Decodable {
    var fullyDetailed = false
    var tmdbId: String = ""
    var imdbId: String = ""
    var title: String = ""
    var portraitPath: String = ""
    var backdropPath: String = ""
    var contentRating: String = ""
    var genres: [String] = [] // For all possible values see: https://developers.themoviedb.org/3/genres/get-movie-list
    var releaseDate: Date!
    var alternativeReleaseDates: [Date] = []
    var runtime: Int = 0 // Movie duration in minutes
    var userScore: Double = 0 // User rating value (0.0-10.0)
    var overview: String = ""
    var revenue: Int = 0
    var clips: [YouTubeItem] = []
    var actors: [ActorItem] = []
    var relatedMovies: [MediaItem] = []

    // Define the properties that should be codable
    private enum CodingKeys: String, CodingKey {
        case fullyDetailed
        case tmdbId
        case imdbId
        case title
        case portraitPath
        case backdropPath
        case contentRating
        case genres
        case releaseDate
        case runtime
        case userScore
        case overview
        case revenue
    }
    
    lazy var shortOverview: String = {
        var shortOverview = ""
        
        // Get first sentence
        overview.enumerateSubstrings(in: overview.startIndex..<overview.endIndex, options: .bySentences) { (substring, substringRange, enclosingRange, stop) in
            if let sentence = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !sentence.isEmpty {
                shortOverview = sentence
            }
            stop = true
        }
        return shortOverview
    }()
    
    /// Duration in seconds
    var duration: Double {
        return Double(runtime) * 60.0
    }
    
    override init() {
        super.init()
    }
    
    private var _portraitAverageColor: UIColor?
    private var _backdropAverageColor: UIColor?

    func averageColor(of imageType: MediaItemImageType, completion: @escaping (UIColor?) -> Void) {
        // Return cached `averageColor` result if exists
        if imageType == .portrait && _portraitAverageColor != nil {
            completion(_portraitAverageColor)
            return
        }
        if imageType == .backdrop && _backdropAverageColor != nil {
            completion(_backdropAverageColor)
            return
        }
        
        let imagePath = imageType == .backdrop ? backdropPath : portraitPath
        guard let imageUrl = URL(string: imagePath) else {
            completion(nil)
            return
        }
        
        ImagePipeline.shared.loadImage(with: imageUrl, progress: nil) { [weak self] (result) in
            switch result {
            case let .success(response):
                let averageColor = response.image.averageColor?.lighter()
                
                // Cache result
                if imageType == .portrait {
                    self?._portraitAverageColor = averageColor
                }
                else if imageType == .backdrop {
                    self?._backdropAverageColor = averageColor
                }
                
                completion(averageColor)
            case .failure(_): completion(nil)
            }
        }
    }
    
}
