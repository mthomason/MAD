//
//  RptqQueryTable+Extras.m
//  Reports
//
//  Created by Michael Thomason on 3/12/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqQueryTable+Extras.h"

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"

#import "RptqDatabase.h"
#import "RptqDatabase+Extras.h"

#import "RptqQuery.h"
#import "RptqQuery+Extras.h"

#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"

#import "RptqDatabaseSchemaTable.h"

@implementation RptqQueryTable (Extras)


#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: NSStringFromSelector(@selector(identifier))
                                                                     ascending: NO];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryTable class])];
    [request setSortDescriptors: @[sortDescriptor]];
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

+ (instancetype)queryTableWithObjectID:(NSManagedObjectID *)objectID managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    return (RptqQueryTable *)[managedObjectContext objectRegisteredForID:objectID];
}

+ (RptqQueryTable *)queryTableFactoryForSchemaTable:(RptqDatabaseSchemaTable *)databaseSchemaTable
                                           database:(RptqDatabase *)database {

    //RptqDatabase *database = [document defaultDatabase];
    RptqQuery *query = [database defaultQuery];
    
    NSSet *queryTables = [query hasQueryTables];
    NSInteger dupeCtr = 0;
    for (RptqQueryTable *queryTable in queryTables) {
        @autoreleasepool {
            if ([[[queryTable databaseSchemaTable] objectID] isEqual:[databaseSchemaTable objectID]]) {
                dupeCtr++;
            }
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
    return queryTable;
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
    char buf[12];
    sprintf(buf, "%ld", (long)index);
    NSString *indexString = @(buf);
    return [tableName stringByAppendingString:indexString];
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
