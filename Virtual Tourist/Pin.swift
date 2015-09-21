//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Ivan Kodrnja on 12/09/15.
//  Copyright (c) 2015 Ivan Kodrnja. All rights reserved.
//

import UIKit
import CoreData
import MapKit

@objc(Pin)

class Pin : NSManagedObject, MKAnnotation {
    
    struct Keys {
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let pictures = "pictures"
    }

    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var photos: [Photo]
    
    var safeCoordinate: CLLocationCoordinate2D? = nil
    
    var coordinate: CLLocationCoordinate2D {
        return safeCoordinate!
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        safeCoordinate = CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        // Core Data
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        
        // Dictionary
        latitude = dictionary[Keys.latitude] as! Double
        longitude = dictionary[Keys.longitude] as! Double
        
        
        safeCoordinate = CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    // MARK - MKAnnotation
    /*
    var coordinate: CLLocationCoordinate2D {
        
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set {
            self.latitude = newValue.latitude
            self.longitude = newValue.longitude
        }
      

    }
*/
}
