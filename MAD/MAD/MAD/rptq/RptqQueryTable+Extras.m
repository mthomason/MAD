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
        RptqQueryTable *lastObject = [fetchResults lastObject];
        identifier = lastObject.identifier.unsignedIntegerValue + 1;
    }
    NSNumber *identifierObj = @(identifier);
    self.identifier = identifierObj;
    
    NSNumber *x = @(CGPointZero.x);
    NSNumber *y = @(CGPointZero.y);
    NSNumber *w = @(CGSizeZero.width);
    NSNumber *h = @(CGSizeZero.height);
    NSNumber *yeah = @(YES);
    self.designerOriginX = x;
    self.designerOriginY = y;
    self.designerSizeWidth = w;
    self.designerSizeHeight = h;
    self.designerInitalLayout = yeah;
    
}

+ (instancetype)queryTableWithObjectID:(NSManagedObjectID *)objectID managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    return (RptqQueryTable *)[managedObjectContext objectRegisteredForID:objectID];
}

+ (RptqQueryTable *)queryTableFactoryForSchemaTable:(RptqDatabaseSchemaTable *)databaseSchemaTable
                                           database:(RptqDatabase *)database NS_RETURNS_RETAINED {

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
    return self.dropIndex.unsignedIntegerValue == 0 ?
                self.databaseSchemaTable.name : [self queryAlias];
}

- (NSString *)queryAlias {
    char buf[12];
    sprintf(buf, "%ld", (long)self.dropIndex.integerValue);
    NSString *indexString = @(buf);
    return [self.databaseSchemaTable.name stringByAppendingString:indexString];
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
