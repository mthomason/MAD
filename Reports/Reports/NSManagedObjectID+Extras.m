//
//  NSManagedObjectID+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "NSManagedObjectID+Extras.h"
#import "MTManagedDocumentReport.h"
#import "NSError+UserInterface.h"
#import "AppDelegate.h"

@implementation NSManagedObjectID (Extras)

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
    NSString *result = nil;
    MTManagedDocumentReport *document = [[AppDelegate activeDocument] document];
    NSManagedObjectContext *managedObjectContext = [document managedObjectContext];
    NSError *error = nil;
    id existingObject = [managedObjectContext existingObjectWithID:self error:&error];
    if (error == nil) {
        if ([existingObject conformsToProtocol:@protocol(MTProtocolLog)]) {
            result = [existingObject toStringHumanReadable];
        } else {
            result = [self toString];
        }
    } else {
        [error presentErrorToUser];
    }
    return result;
}

- (NSString *)toString {
    return [NSString stringWithFormat:@"%@", self];
}

- (NSString *)toStringDebug {
    return [NSString stringWithFormat:@"%@", self];
}

@end