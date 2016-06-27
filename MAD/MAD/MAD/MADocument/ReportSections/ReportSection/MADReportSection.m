//
//  MADReportSection.m
//  MAD
//
//  Created by Michael Thomason on 6/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADReportSection.h"
#import <CoreData/NSManagedObjectID.h>

@interface MADReportSection ()

    @property (nonatomic, readwrite, copy)                              NSManagedObjectID *objectID;
    @property (nonatomic, readwrite, strong, getter=hasReportRows)      MADReportRows *reportRows;

@end

@implementation MADReportSection

@end
