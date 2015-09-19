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
        static let url = "url_m"
    }
    
    @NSManaged var url : String
    @NSManaged var pin : Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        // Core Data
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        // Dictionary
        url = dictionary[Keys.url] as! String
    }
    
}
