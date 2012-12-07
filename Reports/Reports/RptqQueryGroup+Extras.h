//
//  RptqQueryGroup_Extras.h
//  TheReportViewer
//
//  Created by Michael Thomason on 3/7/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryGroup.h"
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Constants.h"
#import "RptqField.h"
#import "RptqDocument+Extras.h"

@interface RptqQueryGroup (Extras)

+ (NSInteger)numberOfGroupsForManagedObjectContext:(NSManagedObjectContext *)objectContext;
+ (RptqQueryGroup *)createAndInsertQueryGroupFor:(RptqField *)field  andSort:(MNSSortOrder)sortOrder inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end