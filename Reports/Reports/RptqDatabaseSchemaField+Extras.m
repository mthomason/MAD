//
//  RptqDatabaseSchemaField+Extras.m
//  Reports
//
//  Created by Michael Thomason on 11/11/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
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
    [result setFieldType:[schemaField dataType]];
    [result setFieldTypeNative:[schemaField dataTypeNative]];
    [result setDecimals:[schemaField decimals]];
    [result setPrimaryKey:[schemaField primaryKey]];
    return [result autorelease];
}

+ (id)getFieldForObjectID:(NSManagedObjectID *)objectID fromObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDatabaseSchemaField class])];
    request.predicate = [NSPredicate predicateWithFormat:@"self == %@", objectID];
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:request error:&error];
    RptqDatabaseSchemaField *result = nil;
    if (results) result = [results lastObject];
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
        case MTDataTypeDate:
            result = NSLocalizedString(@"Date", @"Date data type.");
        case MTDataTypeImage:
            result = NSLocalizedString(@"Image", @"Image data type.");
            break;
        case MTDataTypeNumber:
            result = NSLocalizedString(@"Number", @"Number data type.");
            break;
        case MTDataTypeString:
            result = NSLocalizedString(@"String", @"String data type.");
            break;
        default:
            result = @"";
            break;
    }
    return result;
}

@end
