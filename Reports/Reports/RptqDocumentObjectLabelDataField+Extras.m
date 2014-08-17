//
//  RptqDocumentObjectLabelDataField+Extras.m
//  Reports
//
//  Created by Michael Thomason on 2/29/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocumentObjectLabelDataField+Extras.h"
#import "RptqDocument.h"
#import "RptqDocumentObject+Extras.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDocumentSection+Extras.h"
#import "MTDatabaseField.h"

@implementation RptqDocumentObjectLabelDataField (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentObjectLabelDataField class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: @[sortDescriptor]];
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
    switch (flag) {
        case NSSnapshotEventMergePolicy:
            break;
        case NSSnapshotEventRefresh:
            break;
        case NSSnapshotEventRollback:
            break;
        case NSSnapshotEventUndoDeletion:
            break;
        case NSSnapshotEventUndoInsertion:
            break;
        case NSSnapshotEventUndoUpdate:
            break;
        default:
            break;
    }
}

- (NSString *)formattedString:(MTDataType)dataType forValue:(id)value {
    return [[self parentObjectLabelDataField] formattedString:dataType forValue:value];
}

#pragma mark - RptqDocumentObjectFactory

+ (instancetype)getElementForObjectID:(NSManagedObjectID *)objectId fromObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSManagedObject *result = [managedObjectContext objectRegisteredForID:objectId];
    return (RptqDocumentObjectLabelDataField *)result;
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqual:sender]) {
        result = YES;
    } else {
        RptqDocumentObjectLabelDataField *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

@end
