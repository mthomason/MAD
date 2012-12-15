//
//  RptqDocumentObjectLabelDataField+Extras.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/29/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObjectLabelDataField+Extras.h"

@implementation RptqDocumentObjectLabelDataField (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentObjectLabelDataField class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqDocumentObjectLabelDataField *lastObject = [fetchResults lastObject];
        identifier = [[lastObject identifier] integerValue] + 1;
    }
    [self setIdentifier:@(identifier)];
    
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flag {
    [super awakeFromSnapshotEvents:flag];
}

#pragma mark - Static

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

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqualTo:sender]) {
        result = YES;
    } else {
        RptqDocumentObjectLabelDataField *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

@end