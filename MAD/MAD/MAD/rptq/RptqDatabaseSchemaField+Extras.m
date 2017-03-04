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

- (MADDatabaseField *)databaseFieldWrapper {
    MADDatabaseField *result = [[MADDatabaseField alloc] init];
    result.name = self.name;
    result.fieldType = self.dataType;
    result.fieldTypeNative = self.dataTypeNative;
    result.decimals = self.decimals;
    result.primaryKey = self.primaryKey;
    return result;
}

+ (instancetype)managedObjectForObjectID:(NSManagedObjectID *)objectID
       andManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    return (RptqDatabaseSchemaField *)[managedObjectContext objectWithID:objectID];
}

- (NSString *)display {
    NSString *display = [[NSString alloc] initWithFormat:@"%@.%@",
                                                         self.inTable.name, self.name];
    return display.lowercaseString;
}

- (SEL)selectorForSorting {
    return MADDataTypeSelectorForSorting(self.dataType);
}

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
    NSString *result;
    result = [[NSString alloc] initWithFormat:@"%@.%@", self.inTable.name, self.name];
    return result;
}

- (NSString *)toString {
    return [self toStringHumanReadable];
}

- (NSString *)toStringDebug {
    NSString *result;
    result = [[NSString alloc] initWithFormat:@"%@", self];
    return result;
}

- (NSString *)fieldTypeDisplay {

    NSString *result = nil;
    switch (self.dataType) {
        case MADDataTypeBit:
            result = NSLocalizedString(@"Bit", @"Bit data type.");
            break;
        case MADDataTypeBlob:
            result = NSLocalizedString(@"Blob", @"Blob data type.");
            break;
        case MADDataTypeDate:
            result = NSLocalizedString(@"Date", @"Date data type.");
            break;
        case MADDataTypeDateTime:
            result = NSLocalizedString(@"Date Time", @"Date data type.");
            break;
        case MADDataTypeDecimal:
            result = NSLocalizedString(@"Decimal", @"Date data type.");
            break;
        case MADDataTypeDouble:
            result = NSLocalizedString(@"Double", @"Date data type.");
            break;
        case MADDataTypeEnum:
            result = NSLocalizedString(@"Enum", @"Date data type.");
            break;
        case MADDataTypeFloat:
            result = NSLocalizedString(@"Float", @"Date data type.");
            break;
        case MADDataTypeGeometry:
            result = NSLocalizedString(@"Geometry", @"Date data type.");
            break;
        case MADDataTypeImage:
            result = NSLocalizedString(@"Image", @"Image data type.");
            break;
        case MADDataTypeInt24:
            result = NSLocalizedString(@"Int24", @"Image data type.");
            break;
        case MADDataTypeInteger:
            result = NSLocalizedString(@"Integer", @"Image data type.");
            break;
        case MADDataTypeLong:
            result = NSLocalizedString(@"Long", @"Image data type.");
            break;
        case MADDataTypeLongLong:
            result = NSLocalizedString(@"Long Long", @"Image data type.");
            break;
        case MADDataTypeNumber:
            result = NSLocalizedString(@"Number", @"Number data type.");
            break;
        case MADDataTypeSet:
            result = NSLocalizedString(@"Set", @"Number data type.");
            break;
        case MADDataTypeShort:
            result = NSLocalizedString(@"Short", @"Number data type.");
            break;
        case MADDataTypeString:
            result = NSLocalizedString(@"String", @"String data type.");
            break;
        case MADDataTypeTime:
            result = NSLocalizedString(@"Time", @"Number data type.");
            break;
        case MADDataTypeTimeStamp:
            result = NSLocalizedString(@"Time Stamp", @"Number data type.");
            break;
        case MADDataTypeUnknown:
            result = NSLocalizedString(@"Unknown", @"Number data type.");
            break;
        case MADDataTypeVarChar:
            result = NSLocalizedString(@"Var Char", @"Number data type.");
            break;
        case MADDataTypeYear:
            result = NSLocalizedString(@"Year", @"Number data type.");
            break;
        default:
            result = [[NSString alloc] initWithFormat:@"Type %hd",
                                                      self.dataType];
            break;
    }
    return result;
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
