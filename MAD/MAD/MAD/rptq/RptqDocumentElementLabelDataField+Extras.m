//
//  RptqDocumentElementLabelDataField+Extras.m
//  Reports
//
//  Created by Michael Thomason on 2/29/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocumentElementLabelDataField+Extras.h"

#import <Foundation/NSString.h>
#import <Foundation/NSSortDescriptor.h>

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

#import "RptqDocumentElement+Extras.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqQueryField+Extras.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDocument.h"

#import "RptqDataHelper.h"

@implementation RptqDocumentElementLabelDataField (Extras)

#pragma mark - Overrides

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

- (NSString *)formattedString:(MADDataType)dataType forValue:(id)value {
    return [self formattedString:dataType forValue:value];
}

#pragma mark - RptqDocumentElementFactory

+ (instancetype)getElementForObjectID:(NSManagedObjectID *)objectId
                    fromObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSManagedObject *result = [managedObjectContext objectWithID:objectId];
    return (RptqDocumentElementLabelDataField *)result;
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********\n"];
    [description appendFormat:@"Identifier:             %@\n", self.identifier];
    [description appendFormat:@"Text:                   %@\n", self.text];
    [description appendFormat:@"Table:                  %@\n", self.table];
    [description appendFormat:@"Field:                  %@\n", self.field];
    [description appendFormat:@"*********"];
    return description;
}

- (NSString *)copyDesignerRepresentationText {
    NSString *result = nil;
    result = [self referencesQueryField].toStringReverse;
    return result;
}


@end
