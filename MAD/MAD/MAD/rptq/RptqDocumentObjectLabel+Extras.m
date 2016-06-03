//
//  RptqDocumentObjectLabel+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/15/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocumentObjectLabel+Extras.h"
#import "RptqDocumentObject+Extras.h"
#import <CoreData/NSFetchRequest.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>
#import <CoreData/NSManagedObjectContext.h>

@implementation RptqDocumentObjectLabel (Extras)

- (NSString *)formattedString:(MADDataType)dataType forValue:(id)value {
    return [self.parentObjectLabel formattedString:dataType forValue:value];
}

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName: NSStringFromClass([RptqDocumentObjectLabel class])];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: queryField
                                                                   ascending: NO];
    id sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor, nil];
    request.sortDescriptors = sortDescriptors;
    request.fetchLimit = 1;
    NSError *error = nil;
    NSArray *fetchResults = [self.managedObjectContext executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqDocumentObjectLabel *lastObject = fetchResults.lastObject;
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

+ (instancetype)getElementForObjectID:(NSManagedObjectID *)objectId fromObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSManagedObject *result = [managedObjectContext objectRegisteredForID:objectId];
    return (RptqDocumentObjectLabel *)result;
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********\n"];
    [description appendFormat:@"Identifier:             %@\n", self.identifier];
    [description appendFormat:@"Text:                   %@\n", self.text];
    [description appendFormat:@"*********"];
    return description;
}

@end
