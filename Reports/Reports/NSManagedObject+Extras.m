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
    if ([[self objectID] isTemporaryID]) {
        NSError *error = nil;
        [[self managedObjectContext] obtainPermanentIDsForObjects:[NSArray arrayWithObject: self] error:&error];
        if (error != nil) {
            error = nil;
            [[self managedObjectContext] obtainPermanentIDsForObjects:[NSArray arrayWithObject: self] error:&error];
            if (error != nil) {
                [error presentErrorToUser];
            }
        }
    }
}

@end
