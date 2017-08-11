//
//  RptqDatabaseSchemaField+Extras.m
//  Reports
//
//  Created by Michael Thomason on 11/11/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDatabaseSchemaField+Extras.h"

#import <Foundation/NSBundle.h>

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

#import <MADFoundation/NSString+Common.h>

#import "MADDatabaseField.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"

#import "RptqDataHelper.h"

@implementation RptqDatabaseSchemaField (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    self.identifier = [RptqDataHelper nextIdentifierForClass:[self class]
                                           managedObjectContext:self.managedObjectContext];
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

#pragma mark - Static

+ (instancetype)newDatabaseSchemaFieldFactoryForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                                            andField:(MADDatabaseField *)field {
    
    NSString *entityName = NSStringFromClass([RptqDatabaseSchemaField class]);
    NSEntityDescription *fieldEntity = [NSEntityDescription entityForName: entityName inManagedObjectContext: objectContext];

    RptqDatabaseSchemaField *rptqField = [[self alloc] initWithEntity: fieldEntity
                                       insertIntoManagedObjectContext: objectContext];
    rptqField.name = field.name.copy;
    rptqField.dataType = field.fieldType;
    rptqField.dataTypeNative = field.fieldTypeNative;
    rptqField.decimals = field.decimals;
    rptqField.width = field.width;
    rptqField.primaryKey = field.primaryKey;

    return rptqField;
}

+ (instancetype)managedObjectForObjectID:(NSManagedObjectID *)objectID
       andManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    return (RptqDatabaseSchemaField *)[managedObjectContext objectWithID:objectID];
}

- (NSString *)display {
    return [self.inTable.name stringByAppendingKeyPath:self.name].lowercaseString;
}

- (SEL)selectorForSorting {
    return MADDataTypeSelectorForSorting(self.dataType);
}

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
    return [self.inTable.name stringByAppendingKeyPath:self.name];
}

- (NSString *)toString {
    return [self toStringHumanReadable];
}

- (NSString *)toStringDebug {
    return [NSString stringWithFormat:@"%@", self];
}

+ (NSString *)dataTypeDisplay:(int16_t)dataType {
    switch (dataType) {
        case MADDataTypeBit:
            return NSLocalizedString(@"Bit", @"Bit data type.");
            break;
        case MADDataTypeBlob:
            return NSLocalizedString(@"Blob", @"Blob data type.");
            break;
        case MADDataTypeDate:
            return NSLocalizedString(@"Date", @"Date data type.");
            break;
        case MADDataTypeDateTime:
            return NSLocalizedString(@"Date Time", @"Date data type.");
            break;
        case MADDataTypeDecimal:
            return NSLocalizedString(@"Decimal", @"Date data type.");
            break;
        case MADDataTypeDouble:
            return NSLocalizedString(@"Double", @"Date data type.");
            break;
        case MADDataTypeEnum:
            return NSLocalizedString(@"Enum", @"Date data type.");
            break;
        case MADDataTypeFloat:
            return NSLocalizedString(@"Float", @"Date data type.");
            break;
        case MADDataTypeGeometry:
            return NSLocalizedString(@"Geometry", @"Date data type.");
            break;
        case MADDataTypeImage:
            return NSLocalizedString(@"Image", @"Image data type.");
            break;
        case MADDataTypeInt24:
            return NSLocalizedString(@"Int24", @"Image data type.");
            break;
        case MADDataTypeInteger:
            return NSLocalizedString(@"Integer", @"Image data type.");
            break;
        case MADDataTypeLong:
            return NSLocalizedString(@"Long", @"Image data type.");
            break;
        case MADDataTypeLongLong:
            return NSLocalizedString(@"Long Long", @"Image data type.");
            break;
        case MADDataTypeNumber:
            return NSLocalizedString(@"Number", @"Number data type.");
            break;
        case MADDataTypeSet:
            return NSLocalizedString(@"Set", @"Number data type.");
            break;
        case MADDataTypeShort:
            return NSLocalizedString(@"Short", @"Number data type.");
            break;
        case MADDataTypeString:
            return NSLocalizedString(@"String", @"String data type.");
            break;
        case MADDataTypeTime:
            return NSLocalizedString(@"Time", @"Number data type.");
            break;
        case MADDataTypeTimeStamp:
            return NSLocalizedString(@"Time Stamp", @"Number data type.");
            break;
        case MADDataTypeUnknown:
            return NSLocalizedString(@"Unknown", @"Number data type.");
            break;
        case MADDataTypeVarChar:
            return NSLocalizedString(@"Var Char", @"Number data type.");
            break;
        case MADDataTypeYear:
            return NSLocalizedString(@"Year", @"Number data type.");
            break;
        default:
            return [[NSString alloc] initWithFormat:@"Type %hd", dataType];
            break;
    }
}

- (NSString *)fieldTypeDisplay {
    return [RptqDatabaseSchemaField dataTypeDisplay:self.dataType];
}

- (id)debugQuickLookObject {
    NSMutableString *document = [[NSMutableString alloc] init];
    [document appendFormat:@"********* RptqDatabaseSchemaField *********\n"];
    [document appendFormat:@"Name:              %@\n", self.name];
    [document appendFormat:@"Data type:         %hd\n", self.dataType];
    [document appendFormat:@"Data type native:  %hd\n", self.dataTypeNative];
    [document appendFormat:@"Decimals:          %hd\n", self.decimals];
    [document appendFormat:@"Identifier:        %lld\n", self.identifier];
    [document appendFormat:@"Name:              %@\n", self.name];
    [document appendFormat:@"Primary key:       %@\n", self.primaryKey ? @"YES" : @"NO"];
    [document appendFormat:@"********* RptqDatabaseSchemaField *********"];
    return document;
}

@end
