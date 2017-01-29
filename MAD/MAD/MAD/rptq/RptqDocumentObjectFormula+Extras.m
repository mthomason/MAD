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

#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

#import "RptqDocument+CoreDataClass.h"
#import "RptqDocumentObject+CoreDataClass.h"
#import "RptqDocumentObject+Extras.h"
#import "RptqDocumentSection+CoreDataClass.h"
#import "RptqDocumentSectionRows+CoreDataClass.h"

#import "RptqDataHelper.h"

@implementation RptqDocumentObjectFormula (Extras)

- (NSString *)formattedString:(MADDataType)dataType forValue:(id)value {
    return [self.parentObjectFormula formattedString:dataType forValue:value];
}

- (void)awakeFromInsert {
    [super awakeFromInsert];
    int64_t identifier = [RptqDataHelper nextIdentifierForClass:[self class]
                                           managedObjectContext:self.managedObjectContext];
    CFNumberRef n = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &identifier);
    self.identifier = (__bridge NSNumber * _Nullable)(n);
    CFRelease(n);
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

    NSManagedObjectContext *managedObjectContext = document.managedObjectContext;
    NSEntityDescription *entityDescriptionDocumentObject;
    entityDescriptionDocumentObject = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObject class])
                                                  inManagedObjectContext: managedObjectContext];
    
    NSEntityDescription *entityDescriptionDocumentObjectSubtype;
    entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObjectFormula class])
                                                         inManagedObjectContext: managedObjectContext];
    
    NSString *formulaText = documentObjectDefination[MTDocumentObjectDefinationObject];
    
    RptqDocumentObjectFormula *reportObject = [[RptqDocumentObjectFormula alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                                                 insertIntoManagedObjectContext: managedObjectContext];
    
    reportObject.source = formulaText;
    NSNumber *typeFormula = [[NSNumber alloc] initWithShort: MTDocumentObjectTypeFormula];
    reportObject.type = typeFormula;
    
    NSMutableOrderedSet <RptqDocumentObject *> *hasObjects;
    hasObjects = [document.hasDetailSection.hasRows[0] hasObjects].mutableCopy;
    [hasObjects insertObject:reportObject atIndex:0];
    [document.hasDetailSection.hasRows[0] setHasObjects:hasObjects];
    
    return reportObject;
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
