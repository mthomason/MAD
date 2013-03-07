//
//  RptqDocumentObjectLabel+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/15/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObjectLabel+Extras.h"

@implementation RptqDocumentObjectLabel (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentObjectLabel class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqDocumentObjectLabel *lastObject = [fetchResults lastObject];
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

#pragma mark - RptqDocumentObjectFactory

+ (id)getElementForObjectID:(NSManagedObjectID *)objectId fromObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentObjectLabel class])];
    [request setPredicate: [NSPredicate predicateWithFormat:@"self == %@", objectId]];
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:request error:&error];
    RptqDocumentObjectLabel *result = nil;
    if (results) result = [results lastObject];
    return result;
}

+ (id)addDocumentObject:(id)object toDocument:(id)document {
    
    NSString *labelText = object;
    
    NSEntityDescription *entityDescriptionDocumentObject = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObject class])
                                                                       inManagedObjectContext: [document managedObjectContext]];
    NSEntityDescription *entityDescriptionDocumentObjectLabelDataField = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObjectLabel class])
                                                                                     inManagedObjectContext: [document managedObjectContext]];
    
    RptqDocumentObject *dataObject = [[RptqDocumentObject alloc] initWithEntity: entityDescriptionDocumentObject
                                                 insertIntoManagedObjectContext: [document managedObjectContext]];
    
    RptqDocumentObjectLabel *reportObject = [[RptqDocumentObjectLabel alloc] initWithEntity: entityDescriptionDocumentObjectLabelDataField
                                                                               insertIntoManagedObjectContext: [document managedObjectContext]];
    
    [dataObject setIsLabel: reportObject];
    
    [[dataObject isLabel] setText: labelText];
    [dataObject setType: @(MNSObjectTypeLabelDataField)];
    
    NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet:[[document hasDetailSection] hasObjects]];
    [hasObjects insertObject:dataObject atIndex:0];
    [[document hasDetailSection] setHasObjects:hasObjects];
    [reportObject release];
    
    return [dataObject autorelease];
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqualTo:sender]) {
        result = YES;
    } else {
        RptqDocumentObjectLabel *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

@end
