//
//  FlickrConvenience.swift
//  Virtual Tourist
//
//  Created by Ivan Kodrnja on 18/09/15.
//  Copyright (c) 2015 Ivan Kodrnja. All rights reserved.
//

import Foundation


extension FlickrClient {
    
    
    func getPhotos(_ selectedPin : Pin!, pageNumber : Int = 1, completionHandlerForGetPhotos: @escaping (_ result: [[String: AnyObject]]?, _ error: NSError?) -> Void) {
        
        /* 1. Set the parameters */
        let methodParameters = [FlickrClient.Keys.method: FlickrClient.Constants.method, FlickrClient.Keys.APIKey : FlickrClient.Constants.APIKey, FlickrClient.Keys.lat : selectedPin.coordinate.latitude, FlickrClient.Keys.lon : selectedPin.coordinate.longitude, /*FlickrClient.Keys.boundingBox : createBoundingBoxString(selectedPin),*/ FlickrClient.Keys.safeSearch : FlickrClient.Constants.safeSearch, FlickrClient.Keys.extras : FlickrClient.Constants.extras, FlickrClient.Keys.format : FlickrClient.Constants.format, FlickrClient.Keys.nojsoncallback : FlickrClient.Constants.nojsoncallback, FlickrClient.Keys.perPage : FlickrClient.Constants.perPage, FlickrClient.Keys.pageNumber : pageNumber] as [String : Any]
        
        /* 2. Build the URL */
        let urlString = FlickrClient.Constants.baseSecureUrl + FlickrClient.escapedParameters(methodParameters as [String : AnyObject])
        let url = URL(string: urlString)!
        
        /* 3. Configure the request */
        let request = NSMutableURLRequest(url: url)
        
        /* 4. Make the request */
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGetPhotos(nil, NSError(domain: "getPhotos", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                
                sendError("There was an error with your request: \(error!)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }

            /* 5. Parse the data */
            let parsedResult: [String:AnyObject]
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
     
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* 6. Use the data! */
            if let photosDictionary = parsedResult[FlickrClient.JSONResponseKeys.photos] as? [String:AnyObject] {
                
                // check how many photos are there
                var totalPhotosVal = 0
                if let totalPhotos = photosDictionary[FlickrClient.JSONResponseKeys.total] as? String {
                    totalPhotosVal = (totalPhotos as NSString).integerValue
                }
                
                if totalPhotosVal > 0 {
                    if let photosArray = photosDictionary[FlickrClient.JSONResponseKeys.photo] as? [[String: AnyObject]] {
                        
                        completionHandlerForGetPhotos(photosArray, nil)
                    
                    } else {
                        print("Cant find key 'photo' in \(photosDictionary)")
                    }
                    
                } else {
                    
                    completionHandlerForGetPhotos(nil, NSError(domain: "Results from Flickr", code: 0, userInfo: [NSLocalizedDescriptionKey: "This pin has no images."]))
                }
                
            } else {
                completionHandlerForGetPhotos(nil, NSError(domain: "Results from Flickr", code: 0, userInfo: [NSLocalizedDescriptionKey: "Download (server) error occured. Please retry."]))
            }
            
        }
        /* 7. Start the request */
        task.resume()
    }
    
    
    func getPhotoForImageUrl(_ photo : Photo, completionHandlerForGetPhotoForImageUrl: @escaping (_ success: Bool, _ error: NSError?) -> Void) {
        /* 1. Set the parameters */
        // there are no parameters
        
        /* 2. Build the URL */
        let urlString = photo.imageUrl
        let url = URL(string: urlString!)!
        
        /* 3. Configure the request */
        let request = NSMutableURLRequest(url: url)
        
        /* 4. Make the request */
        let task = session.dataTask(with: request as URLRequest){ (data, response, error) in
        
        /* GUARD: Was there an error? */
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGetPhotoForImageUrl(false, NSError(domain: "getPhotoForImageUrl", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                
                sendError("There was an error with your request: \(error!)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            
        /* 5. Parse the data */
        
            
       /* 6. Use the data! */
       //  Make a fileURL for it
        let fileName = URL(fileURLWithPath: urlString!).lastPathComponent
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] 
        let pathArray = [dirPath, fileName]
        let fileURL = NSURL.fileURL(withPathComponents: pathArray)!
        
        // Save it
        FileManager.default.createFile(atPath: fileURL.path, contents: data, attributes: nil)
        
        // Update the Photo managed object with the file path.
        DispatchQueue.main.async{
            photo.imageFilename = fileURL.path
        }
        completionHandlerForGetPhotoForImageUrl(true, nil)

            
        }
        /* 7. Start the request */
        task.resume()
    }
}
