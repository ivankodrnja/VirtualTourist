//
//  FlickrConvenience.swift
//  Virtual Tourist
//
//  Created by Ivan Kodrnja on 18/09/15.
//  Copyright (c) 2015 Ivan Kodrnja. All rights reserved.
//

import Foundation


extension FlickrClient {
    
    
    func getPhotos(selectedPin : Pin!, pageNumber : Int = 1, completionHandler: (result: [[String: AnyObject]]?, error: NSError?) -> Void) {
        
        /* 1. Set the parameters */
        let methodParameters = [FlickrClient.Keys.method: FlickrClient.Constants.method, FlickrClient.Keys.APIKey : FlickrClient.Constants.APIKey, FlickrClient.Keys.lat : selectedPin.coordinate.latitude, FlickrClient.Keys.lon : selectedPin.coordinate.longitude, /*FlickrClient.Keys.boundingBox : createBoundingBoxString(selectedPin),*/ FlickrClient.Keys.safeSearch : FlickrClient.Constants.safeSearch, FlickrClient.Keys.extras : FlickrClient.Constants.extras, FlickrClient.Keys.format : FlickrClient.Constants.format, FlickrClient.Keys.nojsoncallback : FlickrClient.Constants.nojsoncallback, FlickrClient.Keys.perPage : FlickrClient.Constants.perPage, FlickrClient.Keys.pageNumber : pageNumber]
        
        /* 2. Build the URL */
        let urlString = FlickrClient.Constants.baseSecureUrl + FlickrClient.escapedParameters(methodParameters as! [String : AnyObject])
        let url = NSURL(string: urlString)!
        
        /* 3. Configure the request */
        let request = NSMutableURLRequest(URL: url)
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { data, response, downloadError in
            
            if let error = downloadError {
                
                completionHandler(result: nil, error: error)
            } else {
                /* 5. Parse the data */
                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                /* 6. Use the data! */
                if let error = parsingError {
                    println("Parsing Error: \(error)")
                } else {
                    if let photosDictionary = parsedResult.valueForKey(FlickrClient.JSONResponseKeys.photos) as? [String:AnyObject] {
                        
                        // check how many photos are there
                        var totalPhotosVal = 0
                        if let totalPhotos = photosDictionary[FlickrClient.JSONResponseKeys.total] as? String {
                            totalPhotosVal = (totalPhotos as NSString).integerValue
                        }
                        
                        if totalPhotosVal > 0 {
                            if let photosArray = photosDictionary[FlickrClient.JSONResponseKeys.photo] as? [[String: AnyObject]] {
                                
                                completionHandler(result: photosArray, error: nil)
                            
                            } else {
                                println("Cant find key 'photo' in \(photosDictionary)")
                            }
                            
                        } else {
                            
                            completionHandler(result: nil, error: NSError(domain: "Results from Flick", code: 0, userInfo: [NSLocalizedDescriptionKey: "This pin has no images."]))
                            
                        }
                        
                        
                    } else {
                        completionHandler(result: nil, error: NSError(domain: "Results from Flick", code: 0, userInfo: [NSLocalizedDescriptionKey: "Download (server) error occured. Please retry."]))
                    }
                }
            }
        }
        /* 7. Start the request */
        task.resume()
    }
    
    
    func createBoundingBoxString(selectedPin : Pin!) -> String {
        
        let latitude = selectedPin.coordinate.latitude
        let longitude = selectedPin.coordinate.longitude
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude - FlickrClient.Constants.boundingBoxHalfWidth, FlickrClient.Constants.longitudeMin)
        let bottom_left_lat = max(latitude - FlickrClient.Constants.boundingBoxHalfHeight, FlickrClient.Constants.latitudeMin)
        let top_right_lon = min(longitude + FlickrClient.Constants.boundingBoxHalfHeight, FlickrClient.Constants.longitudeMax)
        let top_right_lat = min(latitude + FlickrClient.Constants.boundingBoxHalfHeight, FlickrClient.Constants.latitudeMax)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    /*
    // Parsing the JSON
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: CompletionHander) {
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError)
        
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            println("Step 4 - parseJSONWithCompletionHandler is invoked.")
            completionHandler(result: parsedResult, error: nil)
        }
    }
    */
}