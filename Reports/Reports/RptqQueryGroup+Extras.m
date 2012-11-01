//
//  RptqQueryGroup+Extras.h
//  TheReportViewer
//
//  Created by Michael Thomason on 3/7/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryGroup+Extras.h"

@implementation RptqQueryGroup (Extras)

+ (NSInteger)numberOfGroupsForManagedObjectContext:(NSManagedObjectContext *)objectContext {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryGroup class])];
    NSError *error = nil;
    NSInteger result = [objectContext countForFetchRequest:request error:&error];
    return (error) ? 0 : result;
}

@end