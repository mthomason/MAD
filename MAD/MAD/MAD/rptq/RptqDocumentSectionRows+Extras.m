//
//  RptqDocumentSectionRows+Extras.m
//  Reports
//
//  Created by Michael Thomason on 3/29/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocumentSectionRows+Extras.h"
#import "RptqDocumentSection.h"
#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>
#import "MADReportSectionRepresentation.h"

@implementation RptqDocumentSectionRows (Extras)

+ (instancetype)newDocumentSectionRowsForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {

    NSEntityDescription *entityDescriptionDocumentSection = [NSEntityDescription entityForName:NSStringFromClass([RptqDocumentSectionRows class])
                                                                        inManagedObjectContext: managedObjectContext];
    id sectionRow = [[self alloc] initWithEntity:entityDescriptionDocumentSection insertIntoManagedObjectContext:managedObjectContext];
    return sectionRow;
}

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter.
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentSectionRows class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: @[sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqDocumentSection *lastObject = [fetchResults lastObject];
        identifier = lastObject.identifier.unsignedIntegerValue + 1;
    }
    NSNumber *identifierObj = @(identifier);
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

- (void)addHasObjectsObjectFixed:(RptqDocumentObject *)value {

    if ([self.hasObjects isKindOfClass:[NSMutableOrderedSet class]]) {

        [(NSMutableOrderedSet *)self.hasObjects addObject:value];

    } else {

        NSMutableOrderedSet* tempSet = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.hasObjects];
        [tempSet addObject:value];
        self.hasObjects = tempSet;

    }
}

- (void)removeHasObjectsObjectFixed:(RptqDocumentObject *)value {

    if ([self.hasObjects isKindOfClass:[NSMutableOrderedSet class]]) {
        
        [(NSMutableOrderedSet *)self.hasObjects removeObject:value];
        
    } else {
    
        NSMutableOrderedSet* tempSet = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.hasObjects];
        [tempSet removeObject:value];
        self.hasObjects = tempSet;
        
    }
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"********* RptqDocumentSectionRows *********\n"];
    [description appendFormat:@"Identifier:             %@\n", self.identifier];
    [description appendFormat:@"Row:                    %li\n", (long)self.rowNumber.integerValue];
    [description appendFormat:@"Height:                 %f\n", self.layoutHeight.floatValue];
    [description appendFormat:@"********* RptqDocumentSectionRows *********"];
    return description;
}

@end
