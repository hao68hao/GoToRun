//
//  Location+CoreDataProperties.swift
//  GoToRun
//
//  Created by lauda on 17/1/24.
//  Copyright © 2017年 lauda. All rights reserved.
//

import Foundation
import CoreData
import GoToRun

extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location");
    }

    @NSManaged public var latitude: NSNumber
    @NSManaged public var longitude: NSNumber
    @NSManaged public var timestamp: Date
    @NSManaged public var run: NSManagedObject

}
