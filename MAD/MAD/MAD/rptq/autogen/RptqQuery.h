//
//  RptqQuery.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqQuery_NSManagedObject_h
#define MAD_RptqQuery_NSManagedObject_h

#import <CoreData/NSManagedObject.h>

@class RptqDatabase, RptqDatabaseSchemaField, RptqQueryGroup, RptqQueryLinks, RptqQueryPredicate, RptqQuerySort, RptqQueryTable;

NS_ASSUME_NONNULL_BEGIN

@interface RptqQuery : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "RptqQuery+CoreDataProperties.h"

#endif
