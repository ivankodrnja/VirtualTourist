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
        let task = session.dataTaskWithRequest(request) { data, response, error in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                
                completionHandler(result: nil, error: error)
                print("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }

            /* 5. Parse the data */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
            } catch {
                parsedResult = nil
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* 6. Use the data! */
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
                        print("Cant find key 'photo' in \(photosDictionary)")
                    }
                    
                } else {
                    
                    completionHandler(result: nil, error: NSError(domain: "Results from Flickr", code: 0, userInfo: [NSLocalizedDescriptionKey: "This pin has no images."]))
                }
                
            } else {
                completionHandler(result: nil, error: NSError(domain: "Results from Flickr", code: 0, userInfo: [NSLocalizedDescriptionKey: "Download (server) error occured. Please retry."]))
            }
            
        }
        /* 7. Start the request */
        task.resume()
    }
    
    
    func getPhotoForImageUrl(photo : Photo,completionHandler: (success: Bool, error: NSError?) -> Void) {
        /* 1. Set the parameters */
        // there are no parameters
        
        /* 2. Build the URL */
        let urlString = photo.imageUrl
        let url = NSURL(string: urlString)!
        
        /* 3. Configure the request */
        let request = NSMutableURLRequest(URL: url)
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { data, response, error in
        
        /* GUARD: Was there an error? */
        guard (error == nil) else {
            
            completionHandler(success: false, error: error)
            print("There was an error with your request: \(error)")
            return
        }
        
        /* GUARD: Did we get a successful 2XX response? */
        guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
            if let response = response as? NSHTTPURLResponse {
                print("Your request returned an invalid response! Status code: \(response.statusCode)!")
            } else if let response = response {
                print("Your request returned an invalid response! Response: \(response)!")
            } else {
                print("Your request returned an invalid response!")
            }
            return
        }
        
        /* GUARD: Was there any data returned? */
        guard let data = data else {
            print("No data was returned by the request!")
            return
        }
            
        /* 5. Parse the data */
        if let result = data {
        
            /* 6. Use the data! */
            //  Make a fileURL for it
            let fileName = urlString.lastPathComponent
            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
            let pathArray = [dirPath, fileName]
            let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
            
            // Save it
            NSFileManager.defaultManager().createFileAtPath(fileURL.path!, contents: result, attributes: nil)
            
            // Update the Photo managed object with the file path.
            dispatch_async(dispatch_get_main_queue()){
                photo.imageFilename = fileURL.path
            }
            completionHandler(success: true, error: nil)
        }

            
        }
        /* 7. Start the request */
        task.resume()
    }
}