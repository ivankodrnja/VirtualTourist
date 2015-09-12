//
//  Picture.swift
//  Virtual Tourist
//
//  Created by Ivan Kodrnja on 12/09/15.
//  Copyright (c) 2015 Ivan Kodrnja. All rights reserved.
//

import UIKit
import CoreData

@objc(Picture)

class Picture : NSManagedObject {
    
    struct Keys {
        static let ID = "id"
        static let url = "url"
    }
    
    @NSManaged var id : NSNumber
    @NSManaged var url : String
    @NSManaged var pin : Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        // Core Data
        let entity = NSEntityDescription.entityForName("Picture", inManagedObjectContext: context)
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        url = dictionary[Keys.url] as! String
        id = dictionary[Keys.ID] as! Int
    }
    
}
