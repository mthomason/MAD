//
//  RptqDocumentObjectAggregate+Extras.m
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObjectAggregate+Extras.h"

@implementation RptqDocumentObjectAggregate (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentObjectAggregate class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqDocumentObjectAggregate *lastObject = [fetchResults lastObject];
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
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentObjectAggregate class])];
    [request setPredicate: [NSPredicate predicateWithFormat:@"self == %@", objectId]];
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:request error:&error];
    RptqDocumentObjectAggregate *result = nil;
    if (results) result = [results lastObject];
    return result;
}

+ (RptqDocumentObject *)addDocumentObject:(NSDictionary *)documentObjectDefination toDocument:(RptqDocument *)document {
    NSEntityDescription *entityDescriptionDocumentObject = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObject class])
                                                                       inManagedObjectContext: [document managedObjectContext]];
    NSEntityDescription *entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObjectAggregate class])
                                                                              inManagedObjectContext: [document managedObjectContext]];
    
    RptqDocumentObject *dataObject = [[RptqDocumentObject alloc] initWithEntity: entityDescriptionDocumentObject
                                                 insertIntoManagedObjectContext: [document managedObjectContext]];
    
    NSString *formulaText = [documentObjectDefination objectForKey:MTDocumentObjectDefinationObject];
    
    RptqDocumentObjectAggregate *reportObject = [[RptqDocumentObjectAggregate alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                                 insertIntoManagedObjectContext: [document managedObjectContext]];
    
    [dataObject setIsAggregate: reportObject];
    
    [[dataObject isFormula] setSource:formulaText];
    
    [dataObject setType: @(MTDocumentObjectTypeAggregate)];
    
    NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet:[[document hasDetailSection] hasObjects]];
    [hasObjects insertObject:dataObject atIndex:0];
    [[document hasDetailSection] setHasObjects:hasObjects];
    [hasObjects release];
    [reportObject release];
    
    return [dataObject autorelease];

}

@end
