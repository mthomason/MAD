//
//  RptqDatabaseSchemaTable+Extras.m
//  Reports
//
//  Created by Michael Thomason on 11/11/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqDatabaseSchemaTable+Extras.h"
#import "RptqDocument+ActiveDocument.h"

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

+ (NSArray *)tablesForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    RptqQuery *query = [RptqDocument queryForActiveDocument];    
    NSString *entityName = NSStringFromClass([RptqDatabaseSchemaTable class]);
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: entityName];
    request.predicate = [NSPredicate predicateWithFormat: @"inQuery == %@", [query objectID]];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending: YES];
    [request setSortDescriptors: @[sortDescriptor]];
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:request error:&error];
    return results;
}

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
    return [rptqTable autorelease];
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
    return [rptqTable autorelease];
}

+ (RptqDatabaseSchemaTable *)getTableForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                      database:(RptqDatabase *)database
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

+ (RptqDatabaseSchemaTable *)getTableForObjectID:(NSManagedObjectID *)objid fromObjectContext:(NSManagedObjectContext *)moc {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDatabaseSchemaTable class])];
    request.predicate = [NSPredicate predicateWithFormat:@"self == %@", objid];
    NSError *error = nil;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    RptqDatabaseSchemaTable *result = nil;
    if (results) result = [results lastObject];
    return result;
}

+ (RptqQueryTable *)addTableToQuery:(RptqDatabaseSchemaTable *)table forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {

    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    NSMutableSet *tablesInQuery = [[NSMutableSet alloc] initWithSet:[query hasQueryTables]];
    
    RptqQueryTable *newQueryTable = [[RptqQueryTable createNewQueryTableForTable:table] retain];
    
    NSMutableSet *newQueryFields = [[NSMutableSet alloc] initWithCapacity:[[table hasFields] count]];
    for (RptqDatabaseSchemaField *field in [table hasFields]) {
        RptqQueryField *newQueryField = [[RptqQueryField createNewQueryFieldForManagedObjectContext:managedObjectContext] retain];
        [newQueryField setInQueryTable:newQueryTable];
        [newQueryField setDatabaseSchemaField:field];
        [newQueryTable setInQuery:query];
        [newQueryFields addObject:newQueryField];
        [newQueryField release];
    }
    [newQueryTable setHasQueryFields:newQueryFields];
    [tablesInQuery addObject:newQueryTable];
    
    [query setHasQueryTables:tablesInQuery];
    [managedObjectContext save:nil];

    [newQueryFields release];
    [tablesInQuery release];
    return [newQueryTable autorelease];
    
/*
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    
    NSSet *tablesInQuery = [query hasTables];
    BOOL isTableAlreadyInQuery = NO;
    for (RptqDatabaseSchemaTable *tableInQuery in tablesInQuery) {
        if ([[tableInQuery name] isEqualToString:[table name]]) {
            isTableAlreadyInQuery = YES;
            break;
        }
    }
    if (!isTableAlreadyInQuery) {
        [query addHasTablesObject:table];
    }
*/
}

+ (NSArray *)namesForTablesInQueryForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    //return [[[[database hasTables] allObjects] retain] autorelease];
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:[[database hasTables] count]];
    for (RptqDatabaseSchemaTable *table in [database hasTables]) {
        [results addObject:[table name]];
    }
    return [results autorelease];
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