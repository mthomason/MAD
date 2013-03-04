//
//  RptqTable+Extras.m
//  Reports
//
//  Created by Michael Thomason on 11/11/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqTable+Extras.h"
#import "RptqDocument+ActiveDocument.h"

@implementation RptqTable (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqTable class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqTable *lastObject = [fetchResults lastObject];
        identifier = [[lastObject identifier] integerValue] + 1;
    }
    [self setIdentifier:@(identifier)];
    [self setDesignerOriginX:@(0.0000f)];
    [self setDesignerOriginY:@(0.0000f)];
    [self setDesignerSizeHeight:@(0.0000f)];
    [self setDesignerSizeWidth:@(0.0000f)];
    [self setDesignerInitalLayout:@(YES)];
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
    NSString *entityName = NSStringFromClass([RptqTable class]);
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: entityName];
    request.predicate = [NSPredicate predicateWithFormat: @"ANY inQuery == %@", [query objectID]];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending: YES];
    [request setSortDescriptors: @[sortDescriptor]];
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:request error:&error];
    return results;
}

+ (RptqTable *)createNewTableForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                                               label:(NSString *)label
                                         labelPlural:(NSString *)labelPlural
                                                name:(NSString *)name
                                         andQueryable:(BOOL)queryable {

    NSString *entityName = NSStringFromClass([RptqTable class]);
    NSEntityDescription *tableEntity = [NSEntityDescription entityForName: entityName inManagedObjectContext: managedObjectContext];
    RptqTable *rptqTable = [[RptqTable alloc] initWithEntity:tableEntity
                              insertIntoManagedObjectContext:managedObjectContext];
    [rptqTable setLabel: label];
    [rptqTable setLabel_plural: labelPlural];
    [rptqTable setName: name];
    [rptqTable setQueryable: [NSNumber numberWithBool: queryable]];
    return [rptqTable autorelease];
}

+ (RptqTable *)createNewTableForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                            andTable:(MTDatabaseTable *)table {
    NSString *entityName = NSStringFromClass([RptqTable class]);
    NSEntityDescription *tableEntity = [NSEntityDescription entityForName: entityName inManagedObjectContext: objectContext];
    RptqTable *rptqTable = [[RptqTable alloc] initWithEntity:tableEntity insertIntoManagedObjectContext:objectContext];
    [rptqTable setLabel: [table label]];
    [rptqTable setLabel_plural: [table labelPlural]];
    [rptqTable setName: [table name]];
    [rptqTable setQueryable: [NSNumber numberWithBool: [table queryable]]];
    return [rptqTable autorelease];
}

+ (RptqTable *)getTableForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                      database:(RptqDatabase *)database
                                  andTableName:(NSString *)name {

    NSSet *tables = [database hasTables];
    RptqTable *result = nil;
    for (RptqTable *table in tables) {
        if ([[table name] isEqualToString:name]) {
            result = table;
            break;
        }
    }
    return result;
}

+ (id)getTableForObjectID:(NSManagedObjectID *)objid fromObjectContext:(NSManagedObjectContext *)moc {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqTable class])];
    request.predicate = [NSPredicate predicateWithFormat:@"self == %@", objid];
    NSError *error = nil;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    RptqTable *result = nil;
    if (results) result = [results lastObject];
    return result;
}

+ (void)addTableToQuery:(RptqTable *)table forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    
    NSSet *tablesInQuery = [query hasTables];
    BOOL isTableAlreadyInQuery = NO;
    for (RptqTable *tableInQuery in tablesInQuery) {
        if ([[tableInQuery name] isEqualToString:[table name]]) {
            isTableAlreadyInQuery = YES;
            break;
        }
    }
    if (!isTableAlreadyInQuery) {
        [query addHasTablesObject:table];
    }
}

+ (NSUInteger)countOfTablesInQueryForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSUInteger result = 0;
    if (managedObjectContext) {
        RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
        RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
        RptqQuery *query = [[database hasQueries] anyObject];
        result = [[query hasTables] count];
    }
    return result;
}

+ (NSArray *)namesForTablesInQueryForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:[[query hasTables] count]];
    for (RptqTable *table in [query hasTables]) {
        [results addObject:[table name]];
    }
    return [results autorelease];
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if (self == sender) {
        result = YES;
    } else {
        RptqTable *s = sender;
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