//
//  RptqDatabaseSchemaTable+Extras.m
//  Reports
//
//  Created by Michael Thomason on 11/11/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDatabaseSchemaTable+Extras.h"

#import <CoreFoundation/CFNumber.h>

#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

#import <MADAPI/MADDatabaseTable.h>

#import "RptqDocument+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqDatabase+Extras.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQuery.h"
#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"

#import "RptqDataHelper.h"

@implementation RptqDatabaseSchemaTable (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    if (self.managedObjectContext.parentContext && self.identifier <= 0) {
        [[NSNotificationCenter defaultCenter] willChangeValueForKey:NSStringFromSelector(@selector(identifier))];
        self.identifier = [RptqDataHelper nextIdentifierForClass:[self class]
                                            managedObjectContext:self.managedObjectContext];
        [[NSNotificationCenter defaultCenter] didChangeValueForKey:NSStringFromSelector(@selector(identifier))];
    }
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

+ (NSFetchRequest<RptqDatabaseSchemaTable *> *)fetchRequestSortTables {
    NSString *entityName = NSStringFromClass([RptqDatabaseSchemaTable class]);
    NSFetchRequest *request;
    NSSortDescriptor *sort;
    request = [NSFetchRequest fetchRequestWithEntityName: entityName];
    NSString *keyName = NSStringFromSelector(@selector(name));
    request.resultType = NSManagedObjectResultType;
    sort = [NSSortDescriptor sortDescriptorWithKey: keyName
                                         ascending: YES];
    
    request.sortDescriptors = [[NSArray alloc] initWithObjects:sort, nil];
    return request;
}

+ (instancetype)newDatabaseSchemaTableFactoryForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                                                                name:(NSString *)name
                                                        andQueryable:(BOOL)queryable {
    
    NSString *entityName = NSStringFromClass([self class]);
    
    NSEntityDescription *tableEntity = [NSEntityDescription entityForName: entityName
                                                   inManagedObjectContext: managedObjectContext];
    RptqDatabaseSchemaTable *rptqTable = [[self alloc] initWithEntity:tableEntity
                                       insertIntoManagedObjectContext:managedObjectContext];

    rptqTable.name = name.copy;
    rptqTable.queryable = queryable;
    
    return rptqTable;
}

+ (instancetype)newDatabaseSchemaTableFactoryForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                                            andTable:(MADDatabaseTable *)table {
    
    NSString *entityName = NSStringFromClass([self class]);
    
    NSEntityDescription *tableEntity = [NSEntityDescription entityForName: entityName
                                                   inManagedObjectContext: objectContext];
    RptqDatabaseSchemaTable *rptqTable;
    rptqTable = [[self alloc] initWithEntity:tableEntity
              insertIntoManagedObjectContext:objectContext];

    rptqTable.name = table.name.copy;
    rptqTable.queryable = table.queryable;
    
    return rptqTable;
}

+ (RptqDatabaseSchemaTable *)databaseSchemaTableForDatabase:(RptqDatabase *)database andTableName:(NSString *)name {

    NSSet *tables = database.hasTables;
    RptqDatabaseSchemaTable *result = nil;
    for (RptqDatabaseSchemaTable *table in tables) {
        if ([table.name isEqualToString:name]) {
            result = table;
            break;
        }
    }
    return result;
}

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
    return self.name;
}

- (NSString *)toString {
    return self.name;
}

- (NSString *)toStringDebug {
    return self.name;
}

- (id)debugQuickLookObject {
    NSMutableString *document = [[NSMutableString alloc] init];
    [document appendFormat:@"*********\n"];
    [document appendFormat:@"Name:              %@\n", self.name];
    [document appendFormat:@"Queryable:         %@\n", self.queryable ? @"YES" : @"NO"];
    [document appendFormat:@"Fields:            %@\n", self.hasFields];
    [document appendFormat:@"*********"];
    return document;
}

@end
