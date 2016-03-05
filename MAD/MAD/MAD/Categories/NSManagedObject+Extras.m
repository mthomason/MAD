//
//  NSManagedObject+Extras.m
//  Reports
//
//  Created by Michael Thomason on 5/20/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "NSManagedObject+Extras.h"

@implementation NSManagedObject (Extras)

- (void)obtainPermanentID {
    if (self.objectID.isTemporaryID) {
        NSError *error = nil;
        [self.managedObjectContext obtainPermanentIDsForObjects:@[self]
                                                          error:&error];
        if (error != nil) {
            error = nil;
            [self.managedObjectContext obtainPermanentIDsForObjects:@[self]
                                                              error:&error];
            NSAssert(error == nil, @"Error %@", error);
        }
    }
}

- (BOOL)saveContext {
    NSError *__autoreleasing error = nil;
    [self.managedObjectContext save:&error];
    NSAssert(error == nil, @"%s\n%@ failed to save context with error %@.\n\t", __PRETTY_FUNCTION__, self, error);
    return error == nil;
}

@end
