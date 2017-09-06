//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Ivan Kodrnja on 03/09/2017.
//  Copyright © 2017 Ivan Kodrnja. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var imageFilename: String?
    @NSManaged public var imageUrl: String?
    @NSManaged public var pin: Pin?

}
