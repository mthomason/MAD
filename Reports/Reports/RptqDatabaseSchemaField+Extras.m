//
//  RptqDatabaseSchemaField+Extras.m
//  Reports
//
//  Created by Michael Thomason on 11/11/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDatabaseField.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"

@implementation RptqDatabaseSchemaField (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];

    // MARK: Auto increment row counter
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDatabaseSchemaField class])];
    request.resultType = NSCountResultType;
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = [[fetchResults firstObject] unsignedIntegerValue] + 1;
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

#pragma mark - Static

+ (instancetype)databaseSchemaFieldFactoryForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                                  andField:(MTDatabaseField *)field {
    
    NSString *entityName = NSStringFromClass([RptqDatabaseSchemaField class]);
    NSEntityDescription *fieldEntity = [NSEntityDescription entityForName: entityName
                                                   inManagedObjectContext: objectContext];

    RptqDatabaseSchemaField *rptqField = [[RptqDatabaseSchemaField alloc] initWithEntity: fieldEntity
                                                          insertIntoManagedObjectContext: objectContext];
    [rptqField setLabel:            [field label]];
    [rptqField setName:             [field name]];
    [rptqField setDataType:         @([field fieldType])];
    [rptqField setDataTypeNative:   @([field fieldTypeNative])];
    [rptqField setDecimals:         @([field decimals])];
    [rptqField setWidth:            @([field width])];
    [rptqField setPrimaryKey:       @([field primaryKey])];
    return rptqField;

}

- (MTDatabaseField *)databaseFieldWrapper {
    MTDatabaseField *result = [[MTDatabaseField alloc] init];
    [result setLabel:[self label]];
    [result setName:self.name];
    [result setFieldType:(MTDataType)[[self dataType] integerValue]];
    [result setFieldTypeNative:[[self dataTypeNative] integerValue]];
    [result setDecimals:[[self decimals] integerValue]];
    [result setPrimaryKey:[[self primaryKey] boolValue]];
    return result;
}

+ (instancetype)managedObjectForObjectID:(NSManagedObjectID *)objectID
       andManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    return (RptqDatabaseSchemaField *)[managedObjectContext objectRegisteredForID:objectID];
}

- (NSString *)display {
    return [[NSString stringWithFormat:@"%@.%@", [[self inTable] name], self.name] lowercaseString];
}

- (SEL)selectorForSorting {
    return [MTDataTypeObject selectorForSorting:[[self dataType] integerValue]];
}

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
    return [NSString stringWithFormat:@"%@.%@", [[self inTable] name], self.name];
}

- (NSString *)toString {
    return [self toStringHumanReadable];
}

- (NSString *)toStringDebug {
    return [NSString stringWithFormat:@"%@", self];
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqual:sender]) {
        result = YES;
    } else {
        RptqDatabaseSchemaField *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

- (NSString *)fieldTypeDisplay {

    NSString *result = nil;
    switch ([[self dataType] integerValue]) {
        case MTDataTypeBit:
            result = NSLocalizedString(@"Bit", @"Bit data type.");
            break;
        case MTDataTypeBlob:
            result = NSLocalizedString(@"Blob", @"Blob data type.");
            break;
        case MTDataTypeDate:
            result = NSLocalizedString(@"Date", @"Date data type.");
            break;
        case MTDataTypeDateTime:
            result = NSLocalizedString(@"Date Time", @"Date data type.");
            break;
        case MTDataTypeDecimal:
            result = NSLocalizedString(@"Decimal", @"Date data type.");
            break;
        case MTDataTypeDouble:
            result = NSLocalizedString(@"Double", @"Date data type.");
            break;
        case MTDataTypeEnum:
            result = NSLocalizedString(@"Enum", @"Date data type.");
            break;
        case MTDataTypeFloat:
            result = NSLocalizedString(@"Float", @"Date data type.");
            break;
        case MTDataTypeGeometry:
            result = NSLocalizedString(@"Geometry", @"Date data type.");
            break;
        case MTDataTypeImage:
            result = NSLocalizedString(@"Image", @"Image data type.");
            break;
        case MTDataTypeInt24:
            result = NSLocalizedString(@"Int24", @"Image data type.");
            break;
        case MTDataTypeInteger:
            result = NSLocalizedString(@"Integer", @"Image data type.");
            break;
        case MTDataTypeLong:
            result = NSLocalizedString(@"Long", @"Image data type.");
            break;
        case MTDataTypeLongLong:
            result = NSLocalizedString(@"Long Long", @"Image data type.");
            break;
        case MTDataTypeNumber:
            result = NSLocalizedString(@"Number", @"Number data type.");
            break;
        case MTDataTypeSet:
            result = NSLocalizedString(@"Set", @"Number data type.");
            break;
        case MTDataTypeShort:
            result = NSLocalizedString(@"Short", @"Number data type.");
            break;
        case MTDataTypeString:
            result = NSLocalizedString(@"String", @"String data type.");
            break;
        case MTDataTypeTime:
            result = NSLocalizedString(@"Time", @"Number data type.");
            break;
        case MTDataTypeTimeStamp:
            result = NSLocalizedString(@"Time Stamp", @"Number data type.");
            break;
        case MTDataTypeUnknown:
            result = NSLocalizedString(@"Unknown", @"Number data type.");
            break;
        case MTDataTypeVarChar:
            result = NSLocalizedString(@"Var Char", @"Number data type.");
            break;
        case MTDataTypeYear:
            result = NSLocalizedString(@"Year", @"Number data type.");
            break;
        default:
            result = [NSString stringWithFormat:@"Type %ld", (long)[[self dataType] integerValue]];
            break;
    }
    return result;
}

@end
