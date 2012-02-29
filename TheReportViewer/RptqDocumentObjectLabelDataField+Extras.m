//
//  RptqDocumentObjectLabelDataField+Extras.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/29/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObjectLabelDataField+Extras.h"

@implementation RptqDocumentObjectLabelDataField (Extras)

+ (RptqDocumentObjectLabelDataField *)labelDataFieldForManagedObjectContext:(NSManagedObjectContext *)objectContext withObjectID:(NSManagedObjectID *)objid {
    RptqDocumentObjectLabelDataField *result = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentObjectLabelDataField class])];
    request.predicate = [NSPredicate predicateWithFormat:@"self == %@", objid];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"table" ascending:YES];
    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSError *error = nil;
    NSArray *results = [[objectContext executeFetchRequest:request error:&error] retain];
    if ([results count] == 1) {
        result = [[[results objectAtIndex: 0] retain] autorelease];
    } else if ([results count] > 1) {
        NSLog(@"Error: Why is it like this? %@ in %@!", objid, objectContext);
        result = [[[results objectAtIndex: 0] retain] autorelease];
    } else {
        NSLog(@"Warning: Could not find %@ in %@.", objid, objectContext);
    }
    [results release];
    return result;
}

@end