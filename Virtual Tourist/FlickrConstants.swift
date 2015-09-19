//
//  FlickrConstants.swift
//  Virtual Tourist
//
//  Created by Ivan Kodrnja on 18/09/15.
//  Copyright (c) 2015 Ivan Kodrnja. All rights reserved.
//

extension FlickrClient {
    
    struct Constants {
        static let baseSecureUrl: String = "https://api.flickr.com/services/rest/"
        static let APIKey = "5a45f3c267e5bec037ae6afe4b9b1469"
        static let method = "flickr.photos.search"
        static let boundingBoxHalfWidth = 1.0
        static let boundingBoxHalfHeight = 1.0
        static let latitudeMin = -90.0
        static let latitudeMax = 90.0
        static let longitudeMin = -180.0
        static let longitudeMax = 180.0
        static let safeSearch = "1"
        static let extras = "url_m"
        static let format = "json"
        static let nojsoncallback = "1"
        static let perPage = "21"
        static let page = 1
    }
    
    struct Keys {
        static let method = "method"
        static let APIKey = "api_key"
        static let boundingBox = "bbox"
        static let safeSearch = "safe_search"
        static let extras = "extras"
        static let format = "format"
        static let nojsoncallback = "nojsoncallback"
        static let perPage = "per_page"
        static let pageNumber = "page"
        static let lat = "lat"
        static let lon = "lon"
        
    }
    
    struct JSONResponseKeys {
        static let photos = "photos"
        static let photo = "photo"
        static let pages = "pages"
        static let total = "total"
    }
    
}
    