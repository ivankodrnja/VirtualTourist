//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Ivan Kodrnja on 12/09/15.
//  Copyright (c) 2015 Ivan Kodrnja. All rights reserved.
//
/*
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

    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
        
    }
    
    init(dictionary: [String : AnyObject], pin: Pin, context: NSManagedObjectContext) {
        // Core Data
        let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context)
        super.init(entity: entity!, insertInto: context)
        
        // Dictionary
        self.imageUrl = dictionary[Keys.imageUrl] as! String
        
        self.pin = pin
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

    
    override func prepareForDeletion() {
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
*/
