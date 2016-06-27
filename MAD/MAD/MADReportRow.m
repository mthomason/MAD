//
//  MADReportRow.m
//  MAD
//
//  Created by Michael Thomason on 6/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADReportRow.h"
#import <CoreData/NSManagedObjectID.h>

@interface MADReportRow ()

    @property (nonatomic, readwrite, copy)      NSManagedObjectID *objectID;
    @property (nonatomic, readwrite, strong)    NSArray <MADDocumentObject *> *documentObjects;

@end

@implementation MADReportRow

@end
