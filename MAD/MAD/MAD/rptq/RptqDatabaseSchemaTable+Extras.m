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

#import "RptqDatabaseSchemaTable+Extras.h"

#import <CoreFoundation/CFNumber.h>

#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

#import "RptqDocument+Extras.h"
#import "RptqDatabaseSchemaTable+CoreDataClass.h"
#import "RptqDocument+CoreDataClass.h"
#import "RptqDatabase+CoreDataClass.h"
#import "RptqDatabase+Extras.h"
#import "RptqQueryTable+CoreDataClass.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQuery+CoreDataClass.h"
#import "RptqQueryField+CoreDataClass.h"
#import "RptqQueryField+Extras.h"
#import "MTDatabaseTable.h"

#import "RptqDataHelper.h"

@implementation RptqDatabaseSchemaTable (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    int64_t identifier = [RptqDataHelper nextIdentifierForClass:[self class]
                                           managedObjectContext:self.managedObjectContext];
    CFNumberRef n = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &identifier);
    self.identifier = (__bridge NSNumber * _Nullable)(n);
    CFRelease(n);
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

+ (instancetype)newDatabaseSchemaTableFactoryForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                                                               label:(NSString *)label
                                                         labelPlural:(NSString *)labelPlural
                                                                name:(NSString *)name
                                                        andQueryable:(BOOL)queryable {
    
    NSString *entityName = NSStringFromClass([self class]);
    
    NSEntityDescription *tableEntity = [NSEntityDescription entityForName: entityName inManagedObjectContext: managedObjectContext];
    RptqDatabaseSchemaTable *rptqTable = [[self alloc] initWithEntity:tableEntity insertIntoManagedObjectContext:managedObjectContext];
    
    
    NSString *rLabel = [[NSString alloc] initWithString:label];
    rptqTable.label = rLabel;
    
    NSString *rLabelPlural = [[NSString alloc] initWithString:labelPlural];
    rptqTable.label_plural = rLabelPlural;
    
    NSString *rName = [[NSString alloc] initWithString: name];
    rptqTable.name = rName;
    
    NSNumber *rQueryable = [[NSNumber alloc] initWithBool: queryable];
    rptqTable.queryable = rQueryable;
    
    return rptqTable;
}

+ (instancetype)newDatabaseSchemaTableFactoryForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                                            andTable:(MTDatabaseTable *)table {
    
    NSString *entityName = NSStringFromClass([self class]);
    
    NSEntityDescription *tableEntity = [NSEntityDescription entityForName: entityName inManagedObjectContext: objectContext];
    RptqDatabaseSchemaTable *rptqTable = [[self alloc] initWithEntity:tableEntity insertIntoManagedObjectContext:objectContext];
    
    NSString *label = [[NSString alloc] initWithString:table.name];
    rptqTable.label = label;
    
    NSString *labelPlural = [[NSString alloc] initWithString:table.name];
    rptqTable.label_plural = labelPlural;

    NSString *name = [[NSString alloc] initWithString: table.name];
    rptqTable.name = name;
    
    NSNumber *queryable = [[NSNumber alloc] initWithBool: table.queryable];
    rptqTable.queryable = queryable;
    
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
    [document appendFormat:@"Label:             %@\n", self.label];
    [document appendFormat:@"Queryable:         %@\n", self.queryable ? @"YES" : @"NO"];
    [document appendFormat:@"Fields:            %@\n", self.hasFields];
    [document appendFormat:@"*********"];
    return document;
}

@end
