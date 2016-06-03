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
#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>

@implementation RptqDocumentObjectFormula (Extras)

- (NSString *)formattedString:(MADDataType)dataType forValue:(id)value {
    return [self.parentObjectFormula formattedString:dataType forValue:value];
}

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName: NSStringFromClass([RptqDocumentObjectFormula class])];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: queryField
                                                                   ascending: NO];
    id sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor, nil];
    request.sortDescriptors = sortDescriptors;
    request.fetchLimit = 1;
    NSError *error = nil;
    NSArray *fetchResults = [self.managedObjectContext executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqDocumentObjectFormula *lastObject = fetchResults.lastObject;
        identifier = lastObject.identifier.unsignedIntegerValue + 1;
    }
    id identifierObj = [[NSNumber alloc] initWithUnsignedInteger: identifier];
    self.identifier = identifierObj;
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

+ (RptqDocumentObject *)addDocumentObject:(NSDictionary *)documentObjectDefination toDocument:(RptqDocument *)document {

    NSEntityDescription *entityDescriptionDocumentObject = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObject class])
                                                                       inManagedObjectContext: document.managedObjectContext];
    
    NSEntityDescription *entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObjectFormula class])
                                                                              inManagedObjectContext: document.managedObjectContext];
    
    RptqDocumentObject *dataObject = [[RptqDocumentObject alloc] initWithEntity: entityDescriptionDocumentObject
                                                 insertIntoManagedObjectContext: document.managedObjectContext];

    NSString *formulaText = documentObjectDefination[MTDocumentObjectDefinationObject];
    
    RptqDocumentObjectFormula *reportObject = [[RptqDocumentObjectFormula alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                                               insertIntoManagedObjectContext: document.managedObjectContext];
    
    dataObject.isFormula = reportObject;
    dataObject.isFormula.source = formulaText;
    NSNumber *typeFormula = @(MTDocumentObjectTypeFormula);
    dataObject.type = typeFormula;
    
    NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet:[document.hasDetailSection.hasRows[0] hasObjects]];
    [hasObjects insertObject:dataObject atIndex:0];
    [document.hasDetailSection.hasRows[0] setHasObjects:hasObjects];
    
    return dataObject;
}

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
    return self.name;
}

- (NSString *)toString {
    return [self toStringHumanReadable];
}

- (NSString *)toStringDebug {
    return [NSString stringWithFormat:@"%@", self];
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********\n"];
    [description appendFormat:@"Identifier:             %@\n", self.identifier];
    [description appendFormat:@"Name:                   %@\n", self.name];
    [description appendFormat:@"Source:                 %@\n", self.source];
    [description appendFormat:@"Result type:            %@\n", self.resultType];
    [description appendFormat:@"Function scope:         %@\n", self.functionScope];
    [description appendFormat:@"Function type:          %@\n", self.functionType];
    [description appendFormat:@"Input type:             %@\n", self.inputType];
    [description appendFormat:@"*********"];
    return description;
}

@end
