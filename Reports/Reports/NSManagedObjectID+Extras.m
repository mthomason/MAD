//
//  NSManagedObjectID+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/13/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "NSManagedObjectID+Extras.h"
#import "MAReportDocument.h"
#import "NSError+UserInterface.h"
#import "AppDelegate.h"

@implementation NSManagedObjectID (Extras)

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
    return [NSString stringWithFormat:@"%@", self];
}

- (NSString *)toString {
    return [NSString stringWithFormat:@"%@", self];
}

- (NSString *)toStringDebug {
    return [NSString stringWithFormat:@"%@", self];
}

@end
