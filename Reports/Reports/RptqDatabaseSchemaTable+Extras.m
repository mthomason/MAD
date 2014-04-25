//
//  RptqDatabaseSchemaTable+Extras.m
//  Reports
//
//  Created by Michael Thomason on 11/11/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"
#import "RptqDatabase.h"
#import "RptqDatabase+Extras.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQuery.h"
#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"
#import "MTDatabaseTable.h"

@implementation RptqDatabaseSchemaTable (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDatabaseSchemaTable class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqDatabaseSchemaTable *lastObject = [fetchResults lastObject];
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

+ (RptqDatabaseSchemaTable *)createNewTableForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                                               label:(NSString *)label
                                         labelPlural:(NSString *)labelPlural
                                                name:(NSString *)name
                                         andQueryable:(BOOL)queryable {

    NSString *entityName = NSStringFromClass([RptqDatabaseSchemaTable class]);
    NSEntityDescription *tableEntity = [NSEntityDescription entityForName: entityName inManagedObjectContext: managedObjectContext];
    RptqDatabaseSchemaTable *rptqTable = [[RptqDatabaseSchemaTable alloc] initWithEntity:tableEntity
                              insertIntoManagedObjectContext:managedObjectContext];
    [rptqTable setLabel: label];
    [rptqTable setLabel_plural: labelPlural];
    [rptqTable setName: name];
    [rptqTable setQueryable: [NSNumber numberWithBool: queryable]];
    return rptqTable;
}

+ (RptqDatabaseSchemaTable *)createNewTableForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                            andTable:(MTDatabaseTable *)table {
    NSString *entityName = NSStringFromClass([RptqDatabaseSchemaTable class]);
    NSEntityDescription *tableEntity = [NSEntityDescription entityForName: entityName inManagedObjectContext: objectContext];
    RptqDatabaseSchemaTable *rptqTable = [[RptqDatabaseSchemaTable alloc] initWithEntity:tableEntity insertIntoManagedObjectContext:objectContext];
    [rptqTable setLabel: [table label]];
    [rptqTable setLabel_plural: [table labelPlural]];
    [rptqTable setName: [table name]];
    [rptqTable setQueryable: [NSNumber numberWithBool: [table queryable]]];
    return rptqTable;
}

+ (RptqDatabaseSchemaTable *)getTableForDatabase:(RptqDatabase *)database
                                  andTableName:(NSString *)name {

    NSSet *tables = [database hasTables];
    RptqDatabaseSchemaTable *result = nil;
    for (RptqDatabaseSchemaTable *table in tables) {
        if ([[table name] isEqualToString:name]) {
            result = table;
            break;
        }
    }
    return result;
}

+ (id)getTableForObjectID:(NSManagedObjectID *)objectId fromObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSManagedObject *result = [managedObjectContext objectRegisteredForID:objectId];
    return result;
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqual: sender]) {
        result = YES;
    } else {
        RptqDatabaseSchemaTable *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
    return [self name];
}

- (NSString *)toString {
    return [self name];
}

- (NSString *)toStringDebug {
    return [self name];
}

@end