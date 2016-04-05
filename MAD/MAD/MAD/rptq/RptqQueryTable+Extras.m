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

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>

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
        RptqQueryTable *lastObject = fetchResults.lastObject;
        identifier = lastObject.identifier.unsignedIntegerValue + 1;
    }
    NSNumber *identifierObj = @(identifier);
    self.identifier = identifierObj;
    
    NSNumber *x = [[NSNumber alloc] initWithDouble:CGPointZero.x];
    NSNumber *y = [[NSNumber alloc] initWithDouble:CGPointZero.y];
    NSNumber *w = [[NSNumber alloc] initWithDouble:CGSizeZero.width];
    NSNumber *h = [[NSNumber alloc] initWithDouble:CGSizeZero.height];
    NSNumber *yeah = [[NSNumber alloc] initWithBool:YES];
    self.designerOriginX = x;
    self.designerOriginY = y;
    self.designerSizeWidth = w;
    self.designerSizeHeight = h;
    self.designerInitalLayout = yeah;
    
}

+ (instancetype)queryTableWithObjectID:(NSManagedObjectID *)objectID managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    return (RptqQueryTable *)[managedObjectContext objectRegisteredForID:objectID];
}

+ (RptqQueryTable *)newQueryTableForSchemaTable:(RptqDatabaseSchemaTable *)databaseSchemaTable database:(RptqDatabase *)database
                        forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext NS_RETURNS_RETAINED {


    RptqQuery *query = [database defaultQuery];
    NSSet *queryTables = [query hasQueryTables];
    NSInteger dupeCtr = 0;
    for (RptqQueryTable *queryTable in queryTables) {
        @autoreleasepool {
            if ([queryTable.databaseSchemaTable.objectID isEqual:databaseSchemaTable.objectID]) {
                dupeCtr++;
            }
        }
    }
    
    NSEntityDescription *tableEntity = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryTable class]) inManagedObjectContext: managedObjectContext];
    RptqQueryTable *queryTable = [[RptqQueryTable alloc] initWithEntity: tableEntity insertIntoManagedObjectContext: managedObjectContext];

    queryTable.databaseSchemaTable = databaseSchemaTable;
    queryTable.inQuery = query;

    NSNumber *dropIndex = [[NSNumber alloc] initWithInteger: dupeCtr];
    queryTable.dropIndex = dropIndex;
    
    NSString *alias = [[NSString alloc] initWithString:queryTable.tableAlias];
    queryTable.alias = alias;
    
    return queryTable;
}

- (NSString *)tableAlias {
    return self.dropIndex.unsignedIntegerValue == 0 ? self.databaseSchemaTable.name : [self queryAlias];
}

- (NSString *)queryAlias {
    char buf[12];
    sprintf(buf, "%ld", (long)self.dropIndex.integerValue);
    NSString *indexString = @(buf);
    return [self.databaseSchemaTable.name stringByAppendingString:indexString];
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
