//
//  RptqQueryTable+Extras.m
//  Reports
//
//  Created by Michael Thomason on 3/12/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryTable+Extras.h"

@implementation RptqQueryTable (Extras)


#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: NSStringFromSelector(@selector(identifier))
                                                                     ascending: NO];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryTable class])];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    
    if (error == nil) {
        RptqQueryTable *lastObject = [fetchResults lastObject];
        identifier = [[lastObject identifier] integerValue] + 1;
    }
    [self setIdentifier:@(identifier)];
    
    [self setDesignerOriginX:@(CGPointZero.x)];
    [self setDesignerOriginY:@(CGPointZero.y)];
    [self setDesignerSizeWidth:@(CGSizeZero.width)];
    [self setDesignerSizeHeight:@(CGSizeZero.height)];
    [self setDesignerInitalLayout:@(YES)];
    
}

+ (id)getQueryTableForObjectID:(NSManagedObjectID *)objectID fromObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSManagedObject *result = [managedObjectContext objectRegisteredForID:objectID];
    return result;
}

+ (RptqQueryTable *)createNewQueryTableForTable:(RptqDatabaseSchemaTable *)databaseSchemaTable inDocument:(RptqDocument *)document {

    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    
    //for (RptqDatabaseSchemaTable *t in [database hasTables]) {
    //    NSLog(@"T: %@", [t name]);
    //}
    
    NSSet *queryTables = [query hasQueryTables];
    NSInteger dupeCtr = 0;
    for (RptqQueryTable *queryTable in queryTables) {
        if ([[[queryTable databaseSchemaTable] objectID] isEqual:[databaseSchemaTable objectID]]) {
            dupeCtr++;
        }
    }
    
    NSEntityDescription *tableEntity = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryTable class])
                                                   inManagedObjectContext: [databaseSchemaTable managedObjectContext]];
    RptqQueryTable *queryTable = [[RptqQueryTable alloc] initWithEntity: tableEntity
                                         insertIntoManagedObjectContext: [databaseSchemaTable managedObjectContext]];

    
    NSNumber *dropIndex = @(dupeCtr);
    [queryTable setDropIndex:dropIndex];
    
    [queryTable setDatabaseSchemaTable:databaseSchemaTable];
    [queryTable setAlias:[queryTable tableAlias]];

    [queryTable setInQuery:query];
    return [queryTable autorelease];
}

- (NSString *)tableAlias {
    NSUInteger dropIndex = [[self dropIndex] integerValue];
    return dropIndex == 0 ? [[self databaseSchemaTable] name] : [self queryAlias];
}

- (NSString *)queryAlias {
    RptqDatabaseSchemaTable *databaseSchemaTable = [self databaseSchemaTable];
    NSString *tableName = [databaseSchemaTable name];
    NSNumber *dropIndex = [self dropIndex];
    NSInteger index = [dropIndex integerValue];
    return [NSString stringWithFormat:@"%@_%d", tableName, index];
}

+ (NSUInteger)countOfTablesInQueryForDocument:(RptqDocument *)document {
    NSUInteger result = 0;
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    result = [[query hasQueryTables] count];
    return result;
}

+ (NSArray *)queryTablesForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    RptqQuery *query = [RptqDocument queryForActiveDocument];
    NSSet *queryTablesSet = [query hasQueryTables];
    NSSortDescriptor *namesAccending = [[NSSortDescriptor alloc] initWithKey:@"alias" ascending:YES];
    NSArray *sortDescriptors = @[namesAccending];
    NSArray *queryTablesArray = [[queryTablesSet sortedArrayUsingDescriptors:sortDescriptors] retain];
    [namesAccending release];
    return [queryTablesArray autorelease];
}


- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqual:sender]) {
        result = YES;
    } else {
        RptqQueryTable *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

@end
