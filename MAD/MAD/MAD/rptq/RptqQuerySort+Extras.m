//
//  RptqQuerySort+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/15/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqQuerySort+Extras.h"

#import <CoreFoundation/CFNumber.h>

#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>

#import "RptqDataHelper.h"

@implementation RptqQuerySort (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    self.identifier = [RptqDataHelper nextIdentifierForClass:[self class]
                                        managedObjectContext:self.managedObjectContext];
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"***********   RptqQuerySort   ***********\n"];
    [description appendFormat:@"Identifier:             %lld\n", self.identifier];
    [description appendFormat:@"ASC:                    %@\n", self.ascending ? @"YES" : @"NO"];
    [description appendFormat:@"***********   RptqQuerySort   ***********"];
    return description;
}

@end
