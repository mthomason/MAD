//
//  MADQueryFullTableEnumerator.m
//  MAD
//
//  Created by Michael Thomason on 6/10/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryFullTableEnumerator.h"
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSManagedObjectID.h>
#import "RptqDocument.h"

@interface MADQueryFullTableEnumerator ()

    @property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
    @property (nonatomic, assign) int64_t documentObjectIdentifier;

@end

@implementation MADQueryFullTableEnumerator

- (instancetype)initWithDocument:(RptqDocument *)document {
    if (self = [super init]) {
        _documentObjectIdentifier = document.identifier;
        self.managedObjectContext = document.managedObjectContext;

    }
    return self;
}

@end
