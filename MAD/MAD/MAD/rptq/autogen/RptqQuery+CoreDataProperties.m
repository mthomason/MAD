//
//  RptqQuery+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "RptqQuery+CoreDataProperties.h"

@implementation RptqQuery (CoreDataProperties)

+ (NSFetchRequest<RptqQuery *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqQuery"];
}

@dynamic cachedText;
@dynamic identifier;
@dynamic override;
@dynamic overrideText;
@dynamic hasFields;
@dynamic hasQueryCache;
@dynamic hasQueryGroups;
@dynamic hasQueryLinks;
@dynamic hasQueryPredicate;
@dynamic hasQuerySort;
@dynamic hasQueryTables;
@dynamic inDatabase;

@end
