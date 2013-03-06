//
//  RptqQueryGroup_Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/7/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqQueryGroup_Extras_h
#define Reports_RptqQueryGroup_Extras_h

#import "RptqQueryGroup.h"
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Constants.h"
#import "RptqField.h"
#import "RptqDocument+Extras.h"
#import "MTProtocolCompare.h"
#import "MTProtocolEnumerator.h"

@interface RptqQueryGroup (Extras) <MTProtocolCompare, MTProtocolEnumerator>

+ (NSInteger)numberOfGroupsForQuery:(RptqQuery *)query;
+ (RptqQueryGroup *)createQueryGroupFor:(RptqField *)field  andSort:(MNSSortOrder)sortOrder inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (NSString *)fieldNameNice;
- (NSString *)sortDisplayNice;

@end

#endif
