//
//  RptqTable+Extras.m
//  Reports
//
//  Created by Michael Thomason on 11/11/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqTable+Extras.h"

@implementation RptqTable (Extras)

+ (RptqTable *)createNewTableForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                               label:(NSString *)label
                                         labelPlural:(NSString *)labelPlural
                                                name:(NSString *)name
                                         andQueryable:(BOOL)queryable {

    NSString *entityName = NSStringFromClass([RptqTable class]);
    NSEntityDescription *tableEntity = [NSEntityDescription entityForName: entityName
                                                   inManagedObjectContext: objectContext];
    RptqTable *rptqTable = [[RptqTable alloc] initWithEntity:tableEntity
                              insertIntoManagedObjectContext:objectContext];
    [rptqTable setLabel: label];
    [rptqTable setLabel_plural: labelPlural];
    [rptqTable setName: name];
    [rptqTable setQueryable: [NSNumber numberWithBool: queryable]];
    return [rptqTable autorelease];
}

+ (RptqTable *)createNewTableForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                            andTable:(MNSDatabaseTable *)table {
    NSString *entityName = NSStringFromClass([RptqTable class]);
    NSEntityDescription *tableEntity = [NSEntityDescription entityForName: entityName
                                                   inManagedObjectContext: objectContext];
    RptqTable *rptqTable = [[RptqTable alloc] initWithEntity:tableEntity
                              insertIntoManagedObjectContext:objectContext];
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

@end