//
//  RptqDocumentSectionRows+Extras.m
//  Reports
//
//  Created by Michael Thomason on 3/29/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocumentSectionRows+Extras.h"
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>

#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>

#import "RptqDocumentSection.h"

#import "MADReportSectionRepresentation.h"
#import "RptqDataHelper.h"

@implementation RptqDocumentSectionRows (Extras)

+ (instancetype)newDocumentSectionRowsForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {

    NSEntityDescription *entityDescription;
    entityDescription = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentSectionRows class])
                                                   inManagedObjectContext: managedObjectContext];
    id sectionRow = [[self alloc] initWithEntity: entityDescription
                  insertIntoManagedObjectContext: managedObjectContext];
    return sectionRow;
}

- (void)awakeFromInsert {
    [super awakeFromInsert];
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

- (void)addHasObjectsObjectFixed:(RptqDocumentElement *)value {

    if ([self.hasObjects isKindOfClass:[NSMutableOrderedSet class]]) {

        [(NSMutableOrderedSet *)self.hasObjects addObject:value];

    } else {

        NSMutableOrderedSet *tempSet = self.hasObjects.mutableCopy;
        [tempSet addObject:value];
        self.hasObjects = tempSet;

    }
}

- (void)removeHasObjectsObjectFixed:(RptqDocumentElement *)value {

    if ([self.hasObjects isKindOfClass:[NSMutableOrderedSet class]]) {
        
        [(NSMutableOrderedSet *)self.hasObjects removeObject:value];
        
    } else {
    
        NSMutableOrderedSet *tempSet = self.hasObjects.mutableCopy;
        [tempSet removeObject:value];
        self.hasObjects = tempSet;
        
    }
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"********* RptqDocumentSectionRows *********\n"];
    [description appendFormat:@"Row:                    %i\n", self.rowNumber];
    [description appendFormat:@"Height:                 %f\n", self.layoutHeight];
    [description appendFormat:@"********* RptqDocumentSectionRows *********"];
    return description;
}

@end
