//
//  RptqQueryTable+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryTable+CoreDataProperties.h"
#import <CoreData/NSFetchRequest.h>

@implementation RptqQueryTable (CoreDataProperties)

+ (NSFetchRequest<RptqQueryTable *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqQueryTable"];
}

@dynamic alias;
@dynamic designerInitalLayout;
@dynamic designerOriginX;
@dynamic designerOriginY;
@dynamic designerSizeHeight;
@dynamic designerSizeWidth;
@dynamic dropIndex;
@dynamic identifier;
@dynamic databaseSchemaTable;
@dynamic hasQueryFields;
@dynamic inQuery;

@end
