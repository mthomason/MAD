//
//  RptqQueryTable.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqQueryTable_NSManagedObject_h
#define MAD_RptqQueryTable_NSManagedObject_h

#import <CoreData/NSManagedObject.h>

@class RptqDatabaseSchemaTable, RptqQuery, RptqQueryField;

NS_ASSUME_NONNULL_BEGIN

@interface RptqQueryTable : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "RptqQueryTable+CoreDataProperties.h"

#endif
