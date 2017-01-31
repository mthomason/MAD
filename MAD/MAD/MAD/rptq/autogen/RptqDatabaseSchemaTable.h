//
//  RptqDatabaseSchemaTable.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDatabaseSchemaTable_NSManagedObject_h
#define MAD_RptqDatabaseSchemaTable_NSManagedObject_h

#import <CoreData/NSManagedObject.h>

@class RptqDatabase, RptqDatabaseSchemaField, RptqQueryTable;

NS_ASSUME_NONNULL_BEGIN

@interface RptqDatabaseSchemaTable : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "RptqDatabaseSchemaTable+CoreDataProperties.h"

#endif
