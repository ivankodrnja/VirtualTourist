//
//  Photo+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Ivan Kodrnja on 03/09/2017.
//  Copyright © 2017 Ivan Kodrnja. All rights reserved.
//

import Foundation
import UIKit
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {

    struct Keys {
        static let imageUrl = "url_m"
    }
    
    convenience init(dictionary: [String : AnyObject], pin: Pin, context: NSManagedObjectContext) {
        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        // Core Data
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
        
            self.init(entity: ent, insertInto: context)
        
            // Dictionary
            self.imageUrl = dictionary[Keys.imageUrl] as? String
            
            self.pin = pin
            } else {
                fatalError("Unable to find Entity name!")
            }
    }
    
    var image: UIImage? {
        
        if let imageFilename = imageFilename {
            
            let filePathURL = URL(fileURLWithPath: imageFilename)
            let lastPathComponent = filePathURL.lastPathComponent
            let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let pathArray = [dirPath, lastPathComponent]
            let fileURL = NSURL.fileURL(withPathComponents: pathArray)!
            
            return UIImage(contentsOfFile: fileURL.path)
        }
        return nil
    }
    
    
    override public func prepareForDeletion() {
        //Delete the associated image file when the Photo managed object is deleted.
        if let imageFilePath = imageFilename {
            
            let fileName = URL(fileURLWithPath: imageFilePath).lastPathComponent
            
            
            let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let pathArray = [dirPath, fileName]
            let fileURL = NSURL.fileURL(withPathComponents: pathArray)!
            
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch _ {
            }
        }
    }
}
