//
//  Run+CoreDataProperties.swift
//  GoToRun
//
//  Created by lauda on 17/1/24.
//  Copyright © 2017年 lauda. All rights reserved.
//

import Foundation
import CoreData
import GoToRun

extension Run {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Run> {
        return NSFetchRequest<Run>(entityName: "Run");
    }

    @NSManaged public var distance: NSNumber
    @NSManaged public var duration: NSNumber
    @NSManaged public var timestamp: Date
    @NSManaged public var locations: NSOrderedSet

}
