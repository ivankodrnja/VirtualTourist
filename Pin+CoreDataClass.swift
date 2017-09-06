//
//  Pin+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Ivan Kodrnja on 03/09/2017.
//  Copyright © 2017 Ivan Kodrnja. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(Pin)
public class Pin: NSManagedObject, MKAnnotation {
    
    struct Keys {
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let pictures = "pictures"
    }
    
    var safeCoordinate: CLLocationCoordinate2D? = nil
    
    public var coordinate: CLLocationCoordinate2D {
        return safeCoordinate!
    }
    
    convenience init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        // Core Data
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: ent, insertInto: context)
            
            // Dictionary
            latitude = dictionary[Keys.latitude] as! Double as NSNumber
            longitude = dictionary[Keys.longitude] as! Double as NSNumber
            
            
            safeCoordinate = CLLocationCoordinate2DMake(latitude as! CLLocationDegrees, longitude as! CLLocationDegrees)
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
    

}
