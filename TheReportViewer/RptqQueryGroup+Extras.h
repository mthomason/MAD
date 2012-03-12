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

@interface RptqQueryGroup (Extras)

+ (NSInteger)numberOfGroupsForManagedObjectContext:(NSManagedObjectContext *)objectContext;

@end