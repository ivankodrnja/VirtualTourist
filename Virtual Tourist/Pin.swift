//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Ivan Kodrnja on 12/09/15.
//  Copyright (c) 2015 Ivan Kodrnja. All rights reserved.
//

import UIKit
import CoreData

@objc(Pin)

class Pin : NSManagedObject {
    
    struct Keys {
     //   static let ID = "id"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let pictures = "pictures"
    }
    
   // @NSManaged var id : NSNumber
    @NSManaged var latitude : Double
    @NSManaged var longitude : Double
    @NSManaged var photos : [Photo]
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        // Core Data
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        // Dictionary
        latitude = dictionary[Keys.latitude] as! Double
        longitude = dictionary[Keys.longitude] as! Double
       // id = dictionary[Keys.ID] as! Int
    }
    
}
