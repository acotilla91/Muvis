//
//  TMDbAPIService.swift
//  Muvis
//
//  Created by Alejandro Cotilla on 9/6/20.
//  Copyright © 2020 Carolco LLC. All rights reserved.
//

import UIKit
import SwiftDate

class TMDbAPIService: NSObject {
    static let shared = TMDbAPIService()
    private override init() {}
    
    // MARK: - TMDb API Endpoints -
    
    struct TMDbAPI {
        // Load TMDb API key from the "tmdb_key" file in the bundle
        static let key = try! String(contentsOfFile: Bundle.main.path(forResource: "tmdb_key", ofType: nil)!).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        static let base = "https://api.themoviedb.org/3/"
        static let movieDetails = "\(base)movie/<movie-id>?api_key=\(key)&append_to_response=releases,credits,videos"
        static let actorDetails = "\(base)person/<person-id>?api_key=\(key)&append_to_response=movie_credits"
        static let recommended = "\(base)movie/<movie-id>/recommendations?api_key=\(key)"
        static let discover = "\(base)discover/movie?api_key=\(key)&language=en-US&with_original_language=en"
        
        // Using `primary_release_date.lte` to go back 3 months for better chance of the movies being released digitally and/or physically
        static let discoverRipe = "\(base)discover/movie?api_key=\(key)&language=en-US&primary_release_date.lte=\((Date() - 3.months).toISO(.withFullDate))&with_original_language=en"
        
        // For more details on images see: https://developers.themoviedb.org/3/getting-started/images
        static let imageBase = "http://image.tmdb.org/t/p/"
        static let portraitBase = "\(imageBase)w500"
        static let backdropBase = "\(imageBase)w1280"
        static let originalBase = "\(imageBase)original"
        static let profileBase = "\(imageBase)h632"
    }
    
    private var contentRows: [[String: String]] = [
        // Popular movies (likely still in theaters)
        ["Featured": "\(TMDbAPI.discover)&sort_by=popularity.desc&primary_release_date.gte=\((Date() - 3.months).toISO(.withFullDate))"],

        // Current popular movies (guaranteeing digital release)
        ["Popular": "\(TMDbAPI.discoverRipe)&sort_by=popularity.desc"],

        // Big hits in the last year based on revenue
        ["Big Hits": "\(TMDbAPI.discoverRipe)&region=US&sort_by=revenue.desc&primary_release_date.gte=\((Date() - 1.years).toISO(.withFullDate))&vote_count.gte=500"],

        // Fan favorite movies in the last 2 years based on votes
        ["Fan Favorite": "\(TMDbAPI.discoverRipe)&region=US&sort_by=vote_average.desc&vote_count.gte=1000&primary_release_date.gte=\((Date() - 2.years).toISO(.withFullDate))"],

        // Most popular comedies in the last 9 years (excludes movies with the genres: "Adventure", "Animated", "History", "Music", "Fantasy", "Science Fiction" and "Thriller")
        ["Comedies": "\(TMDbAPI.discoverRipe)&region=US&sort_by=popularity.desc&primary_release_date.gte=\((Date() - 9.years).toISO(.withFullDate))&vote_count.gte=500&with_genres=35&without_genres=12,16,36,53,10402,878,14"],

        // Most popular action and adventure movies in the last 5 years that are not comedies or animated movies
        ["Action & Adventure": "\(TMDbAPI.discoverRipe)&region=US&sort_by=popularity.desc&primary_release_date.gte=\((Date() - 5.years).toISO(.withFullDate))&vote_count.gte=500&with_genres=28,12&without_genres=16,35"],

        // Most popular animated movies of the last 10 years with max rating of PG
        ["Animated": "\(TMDbAPI.discoverRipe)&region=US&sort_by=popularity.desc&certification_country=US&certification.lte=PG&primary_release_date.gte=\((Date() - 10.years).toISO(.withFullDate))&vote_count.gte=200&with_genres=16"],

        // Most popular dramas in the last 3 years
        ["Drama": "\(TMDbAPI.discoverRipe)&region=US&sort_by=popularity.desc&primary_release_date.gte=\((Date() - 3.years).toISO(.withFullDate))&vote_count.gte=500&with_genres=18&without_genres=16,35,12,28"]
    ]
    
    // MARK: - TMDb API Requests -

    func requestMediaCategories(_ completion: @escaping ([MediaCategory]) -> Void) {
        DispatchQueue.global().async {
            var categories: [MediaCategory] = []
  
            // Request TMDB movie objects.
            for contentRow in self.contentRows {
                let url = contentRow.map({$0.value})[0]
                let items = self.getTMDBMovieItems(from: url)
                
                // Save category
                if !items.isEmpty {
                    let category = MediaCategory()
                    category.name = contentRow.map({$0.key})[0]

                    category.items = items
                    categories.append(category)
                }
            }
            
            // Send media categories to caller
            DispatchQueue.main.async {
                completion(categories)
            }
        }
    }
    
    func requestFullDetails(for item: MediaItem, completion: @escaping () -> Void) {
        DispatchQueue.global().async {
            let url = TMDbAPI.movieDetails.replacingOccurrences(of: "<movie-id>", with: item.tmdbId)
            let details = URLSession.shared.syncRequestJSON(url: url).json
       
            item.runtime = details["runtime"] as? Int ?? 0
            item.revenue = details["revenue"] as? Int ?? 0

            // Fetch content rating
            guard
                let releases = details["releases"] as? [String: AnyObject],
                let countries = releases["countries"] as? [[String: AnyObject]],
                let usRelease = countries.first(where: { $0["iso_3166_1"] as? String == "US" }),
                let rating = usRelease["certification"] as? String
                else {
                    DispatchQueue.main.async {
                        completion()
                    }
                    return
            }
            item.contentRating = rating
            
            // Fetch alternative dates
            let primaryReleaseDateString = item.releaseDate.toISO(.withFullDate)
            let alternativeDates = countries.map { $0["release_date"] as? String ?? "" }.filter { !$0.isEmpty && $0 != primaryReleaseDateString }.map { $0.toDate()?.date ?? Date() }
            item.alternativeReleaseDates = alternativeDates
            
            // Fetch genres
            if let rawGenres = details["genres"] as? [[String: AnyObject]] {
                item.genres = rawGenres.map { $0["name"] as? String ?? ""}.filter { !$0.isEmpty }
                
                // Limit genres amount to 3
                if item.genres.count > 3 { item.genres = Array(item.genres[..<3]) }
            }
            
            // Fetch trailers and clips
            if
                let tmdbVideos = details["videos"] as? [String: AnyObject],
                let tmdbVideoResults = tmdbVideos["results"] as? [[String: AnyObject]] {
                
                var clips: [YouTubeItem] = []
                for video in tmdbVideoResults {
                    guard
                        let site = video["site"] as? String,
                        site == "YouTube",
                        let title = video["name"] as? String, !title.isEmpty,
                        let tmdbId = video["id"] as? String, !tmdbId.isEmpty,
                        let ytKey = video["key"] as? String, !ytKey.isEmpty,
                        let type = video["type"] as? String, !type.isEmpty
                        else {
                            continue
                    }
                    
                    let ytItem = YouTubeItem()
                    ytItem.title = title
                    ytItem.tmdbId = tmdbId
                    ytItem.youtubeId = ytKey
                    ytItem.type = type
                    
                    clips.append(ytItem)
                }
             
                item.clips = clips
            }
            
            // Fetch cast
            if
                let tmdbCredits = details["credits"] as? [String: AnyObject],
                let tmdbCast = tmdbCredits["cast"] as? [[String: AnyObject]] {
                
                var actors: [ActorItem] = []
                for castMember in tmdbCast {
                    guard
                        let name = castMember["name"] as? String, !name.isEmpty,
                        let tmdbId = castMember["id"] as? Int,
                        let profilePath = castMember["profile_path"] as? String, !profilePath.isEmpty
                        else {
                            continue
                    }

                    let actorItem = ActorItem()
                    actorItem.name = name
                    actorItem.tmdbId = "\(tmdbId)"
                    actorItem.profilePath = TMDbAPI.profileBase + profilePath
                    actors.append(actorItem)
                    
                    // Fetch a max of 10 actors
                    if actors.count > 10 {
                        break
                    }
                }
                
                item.actors = actors
            }
            
            // Get recommended items
            let recommendationsUrl = TMDbAPI.recommended.replacingOccurrences(of: "<movie-id>", with: item.tmdbId)
            item.relatedMovies =  self.getTMDBMovieItems(from: recommendationsUrl, filter: { (mediaItem) -> Bool in
                // Filter in movies released at least 3 months ago only
                return mediaItem.releaseDate <= (Date() - 3.months)
            })

            // Flag the item as fully detailed
            item.fullyDetailed = true

            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func requestFullDetails(for item: ActorItem, completion: @escaping () -> Void) {
        DispatchQueue.global().async {
            let url = TMDbAPI.actorDetails.replacingOccurrences(of: "<person-id>", with: item.tmdbId)
            let details = URLSession.shared.syncRequestJSON(url: url).json
            
            item.biography = details["biography"] as? String ?? ""
            
            // Get actor movies
            let movieCredits = details["movie_credits"] as? [String: AnyObject] ?? [:]
            let tmdbMovies = movieCredits["cast"] as? [[String: AnyObject]] ?? []
            item.relatedMovies = self.getTMDBMovieItems(from: tmdbMovies)
            
            // Flag the item as fully detailed
            item.fullyDetailed = true
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    private func getTMDBMovieItems(from url: String, filter: ((MediaItem) -> Bool)? = nil) -> [MediaItem] {
        let response = URLSession.shared.syncRequestJSON(url: url).json
        let tmdbMovies = response["results"] as? [[String: AnyObject]] ?? []
        return getTMDBMovieItems(from: tmdbMovies, filter: filter)
    }
    
    private func getTMDBMovieItems(from response: [[String: AnyObject]], filter: ((MediaItem) -> Bool)? = nil) -> [MediaItem] {
        // Map TMDB movie objects to our media item model.
        // Only basic data will be set, any other additional data is set once the user
        // navigates to the movie details screen.
        var items: [MediaItem] = []

        
        for tmdbMovie in response {
            // Ensure all required values are available
            guard
                let id = tmdbMovie["id"] as? Int,
                let title = tmdbMovie["title"] as? String,
                let posterPath = tmdbMovie["poster_path"] as? String,
                let backdropPath = tmdbMovie["backdrop_path"] as? String,
                let userScore = tmdbMovie["vote_average"] as? Double,
                let releaseDateString = tmdbMovie["release_date"] as? String,
                let releaseDate = Date(releaseDateString)
                else {
                    continue
            }
            
            let item = MediaItem()
            item.tmdbId = "\(id)"
            item.title = title
            item.portraitPath = TMDbAPI.portraitBase + posterPath
            item.backdropPath = TMDbAPI.backdropBase + backdropPath
            item.releaseDate = releaseDate
            item.userScore = userScore
            item.overview = tmdbMovie["overview"] as? String ?? ""
            
            if filter == nil || filter!(item) {
                items.append(item)
            }
        }
        
        return items
    }
}
