//
//  NSManagedObject+Extras.m
//  Reports
//
//  Created by Michael Thomason on 5/20/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "NSManagedObject+Extras.h"
#import <UIKit/UIManagedDocument.h>
#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSManagedObjectContext.h>

@implementation NSManagedObject (Extras)

- (BOOL)saveContext {
    NSError *__autoreleasing error = nil;
    [self.managedObjectContext save:&error];
    NSAssert(error == nil, @"%s\n%@ failed to save context with error %@.\n\t",
             __PRETTY_FUNCTION__, self, error);
    return error == nil;
}

@end
