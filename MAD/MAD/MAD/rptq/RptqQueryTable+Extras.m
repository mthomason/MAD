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

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>
#import <stdio.h>
#import "madlib.h"

#import "RptqDocument+Extras.h"
#import "RptqDatabase+Extras.h"
#import "RptqQuery+Extras.h"
#import "RptqQueryField+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDataHelper.h"

@implementation RptqQueryTable (Extras)


#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    self.identifier = [RptqDataHelper nextIdentifierForClass:[self class]
                                        managedObjectContext:self.managedObjectContext];
    
}

+ (instancetype)queryTableWithObjectID:(NSManagedObjectID *)objectID
                  managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    return (RptqQueryTable *)[managedObjectContext objectWithID:objectID];
}

+ (RptqQueryTable *)newQueryTableForSchemaTable:(RptqDatabaseSchemaTable *)databaseSchemaTable
                                       database:(RptqDatabase *)database
                        forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {


    RptqQuery *query = database.defaultQuery;
    NSSet *queryTables = query.hasQueryTables;
    NSInteger dupeCtr = 0;
    RptqQueryTable *queryTable;
    for (queryTable in queryTables) {
        if ([queryTable.databaseSchemaTable.objectID isEqual:databaseSchemaTable.objectID]) {
            dupeCtr++;
        }
    }
    
    NSEntityDescription *tableEntity = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryTable class])
                                                   inManagedObjectContext: managedObjectContext];
    queryTable = [[RptqQueryTable alloc] initWithEntity: tableEntity insertIntoManagedObjectContext: managedObjectContext];

    queryTable.databaseSchemaTable = databaseSchemaTable;
    queryTable.inQuery = query;

    NSNumber *dropIndex = [[NSNumber alloc] initWithInteger: dupeCtr];
    queryTable.dropIndex = dropIndex;
    
    NSString *alias = [[NSString alloc] initWithString:queryTable.tableAlias];
    queryTable.alias = alias;
    
    return queryTable;
}

- (NSString *)tableAlias {
    return self.dropIndex.unsignedIntegerValue == 0 ? self.databaseSchemaTable.name : [self copyQueryAlias];
}

- (NSString *)copyQueryAlias {
    char buf[12]; char *ptr;
    ltoa(self.dropIndex.integerValue, buf);
    ptr = buf;
    NSString *indexString = [[NSString alloc] initWithCString:ptr encoding:NSUTF8StringEncoding];
    NSString *databaseName = self.databaseSchemaTable.name.copy;
    NSString *alias = [databaseName stringByAppendingString:indexString];
    return alias;
}

- (BOOL)isEqualTo:(RptqQueryTable *)sender {
    return [sender isEqual:sender] ?
        YES :
        ([sender isKindOfClass:self.class] && [self.identifier isEqualToNumber:sender.identifier]);
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"***********   RptqQueryTable  ***********\n"];
    [description appendFormat:@"Identifier:             %@\n", self.identifier];
    [description appendFormat:@"Alias:                  %@\n", self.alias];
    [description appendFormat:@"Inital layout:          %@\n", self.designerInitalLayout];
    [description appendFormat:@"Frame:                  (%f, %f, %f, %f)\n", self.designerOriginX.floatValue, self.designerOriginY.floatValue, self.designerSizeWidth.floatValue, self.designerSizeHeight.floatValue];
    [description appendFormat:@"***********   RptqQueryTable  ***********"];
    return description;
}

@end
