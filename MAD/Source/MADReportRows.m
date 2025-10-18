//
//  MADReportRows.m
//  MAD
//
//  Created by Michael Thomason on 6/25/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADReportRows.h"
#import <CoreData/NSManagedObjectID.h>

@interface MADReportRows ()

@property (nonatomic, readwrite, copy) NSManagedObjectID *objectID;
@property (nonatomic, readwrite, strong) NSArray <MADReportRow *> *rows;

@end

@implementation MADReportRows

@end
