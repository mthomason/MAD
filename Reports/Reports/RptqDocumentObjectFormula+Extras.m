//
//  RptqDocumentObjectFormula+Extras.m
//  Reports
//
//  Created by Michael Thomason on 3/18/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocumentObjectFormula+Extras.h"
#import "RptqDocument.h"
#import "RptqDocumentObject.h"
#import "RptqDocumentObject+Extras.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSectionRows.h"

@implementation RptqDocumentObjectFormula (Extras)

- (NSString *)formattedString:(MTDataType)dataType forValue:(id)value {
    return [[self parentObjectFormula] formattedString:dataType forValue:value];
}

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentObjectFormula class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqDocumentObjectFormula *lastObject = [fetchResults lastObject];
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

+ (id)documentObjectForObjectID:(NSManagedObjectID *)objectId managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSManagedObject *result = [managedObjectContext objectRegisteredForID:objectId];
    return result;
}

+ (RptqDocumentObject *)addDocumentObject:(NSDictionary *)documentObjectDefination toDocument:(RptqDocument *)document {

    NSEntityDescription *entityDescriptionDocumentObject = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObject class])
                                                                       inManagedObjectContext: [document managedObjectContext]];
    NSEntityDescription *entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObjectFormula class])
                                                                                     inManagedObjectContext: [document managedObjectContext]];
    
    RptqDocumentObject *dataObject = [[RptqDocumentObject alloc] initWithEntity: entityDescriptionDocumentObject
                                                 insertIntoManagedObjectContext: [document managedObjectContext]];

    NSString *formulaText = [documentObjectDefination objectForKey:MTDocumentObjectDefinationObject];
    
    RptqDocumentObjectFormula *reportObject = [[RptqDocumentObjectFormula alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                                               insertIntoManagedObjectContext: [document managedObjectContext]];
    
    [dataObject setIsFormula: reportObject];
    
    [[dataObject isFormula] setSource:formulaText];
    
    [dataObject setType: @(MTDocumentObjectTypeFormula)];
    
    NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet:[[[[document hasDetailSection] hasRows] objectAtIndex:0] hasObjects]];
    [hasObjects insertObject:dataObject atIndex:0];
    [[[[document hasDetailSection] hasRows] objectAtIndex:0] setHasObjects:hasObjects];
    
    return dataObject;
}

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
    return [self name];
}

- (NSString *)toString {
    return [self toStringHumanReadable];
}

- (NSString *)toStringDebug {
    return [NSString stringWithFormat:@"%@", self];
}

@end
