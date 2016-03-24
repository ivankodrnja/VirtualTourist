//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Ivan Kodrnja on 12/09/15.
//  Copyright (c) 2015 Ivan Kodrnja. All rights reserved.
//

import UIKit
import CoreData

@objc(Photo)

class Photo : NSManagedObject {
    
    struct Keys {
        static let imageUrl = "url_m"
    }
    
    @NSManaged var imageFilename : String?
    @NSManaged var imageUrl : String
    @NSManaged var pin : Pin?

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
    }
    
    init(dictionary: [String : AnyObject], pin: Pin, context: NSManagedObjectContext) {
        // Core Data
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        // Dictionary
        self.imageUrl = dictionary[Keys.imageUrl] as! String
        
        self.pin = pin
    }
    
    var image: UIImage? {
        
        if let imageFilename = imageFilename {
            
            let filePathURL = NSURL.fileURLWithPath(imageFilename)
            let lastPathComponent = filePathURL.lastPathComponent!
            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            let pathArray = [dirPath, lastPathComponent]
            let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
            
            return UIImage(contentsOfFile: fileURL.path!)
        }
        return nil
    }

    
    override func prepareForDeletion() {
        //Delete the associated image file when the Photo managed object is deleted.
        if let imageFilePath = imageFilename, fileName = NSURL.fileURLWithPath(imageFilePath).lastPathComponent {
            
            
            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            let pathArray = [dirPath, fileName]
            let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
            
            do {
                try NSFileManager.defaultManager().removeItemAtURL(fileURL)
            } catch _ {
            }
        }
    }
    
}
