//
//  RptqDatabaseSchemaField+Extras.m
//  Reports
//
//  Created by Michael Thomason on 11/11/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "RptqDatabaseSchemaField+Extras.h"

@implementation RptqDatabaseSchemaField (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDatabaseSchemaField class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqDatabaseSchemaField *lastObject = [fetchResults lastObject];
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

#pragma mark - Static

+ (RptqDatabaseSchemaField *)createNewFieldForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                            andField:(MTDatabaseField *)field {
    
    NSEntityDescription *fieldEntity = [NSEntityDescription entityForName: NSStringFromClass([RptqDatabaseSchemaField class])
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
    return [rptqField autorelease];

}

+ (MTDatabaseField *)databaseFieldForSchemaField:(RptqDatabaseSchemaField *)schemaField {

    MTDatabaseField *result = [[MTDatabaseField alloc] init];
    [result setLabel:[schemaField label]];
    [result setName:[schemaField name]];
    [result setFieldType:(MTDataType)[[schemaField dataType] integerValue]];
    [result setFieldTypeNative:[[schemaField dataTypeNative] integerValue]];
    [result setDecimals:[[schemaField decimals] integerValue]];
    [result setPrimaryKey:[[schemaField primaryKey] boolValue]];
    return [result autorelease];
}

+ (id)getFieldForObjectID:(NSManagedObjectID *)objectID fromObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSManagedObject *result = [managedObjectContext objectRegisteredForID:objectID];
    return result;
}

- (NSString *)display {
    return [[NSString stringWithFormat:@"%@.%@", [[self inTable] name], [self name]] lowercaseString];
}

- (SEL)selectorForSorting {
    return [MTDatabaseField selectorForSorting:[[self dataType] integerValue]];
}

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
    return [NSString stringWithFormat:@"%@.%@", [[self inTable] name], [self name]];
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
