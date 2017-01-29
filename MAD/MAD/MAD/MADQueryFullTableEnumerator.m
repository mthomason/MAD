//
//  MADQueryFullTableEnumerator.m
//  MAD
//
//  Created by Michael Thomason on 6/10/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryFullTableEnumerator.h"
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSManagedObjectID.h>
#import "RptqDocument+CoreDataClass.h"

@interface MADQueryFullTableEnumerator ()

    @property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
    @property (nonatomic, copy) NSManagedObjectID *documentObjectID;

@end

@implementation MADQueryFullTableEnumerator

- (instancetype)initWithDocument:(RptqDocument *)document {
    if (self = [super init]) {
        _documentObjectID = document.objectID.copy;
        self.managedObjectContext = document.managedObjectContext;

    }
    return self;
}

@end
