//
//  Errors.swift
//  YoutubeDirectLinkExtractor
//
//  Created by Andrey Sevrikov on 04/03/2018.
//  Copyright © 2018 Andrey Sevrikov. All rights reserved.
//

import Foundation

enum YoutubeError: LocalizedError {
    
    case cantExtractVideoId
    case cantConstructRequestUrl
    case noDataInResponse
    case cantConvertDataToString
    case cantExtractURLFromYoutubeResponse
    case unkown
    case custom(description: String?)
    
    var errorDescription: String? {
        switch self {
        case .custom(let description):
            return description
        case .cantExtractVideoId:
            return "Couldn't extract video id from the url"
        case .cantConstructRequestUrl:
            return "Couldn't construct URL for youtube info request"
        case .noDataInResponse:
            return "No data in youtube info response"
        case .cantConvertDataToString:
            return "Couldn't convert response data to string"
        case .cantExtractURLFromYoutubeResponse:
            return "Couldn't extract url from youtube response"
        case .unkown:
            return "Unknown error occured"
        }
    }
}
