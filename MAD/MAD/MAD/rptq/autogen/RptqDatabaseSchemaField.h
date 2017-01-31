//
//  RptqDatabaseSchemaField.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDatabaseSchemaField_NSManagedObject_h
#define MAD_RptqDatabaseSchemaField_NSManagedObject_h

#import <CoreData/CoreData.h>

@class RptqDatabaseSchemaTable, RptqQuery, RptqQueryField;

NS_ASSUME_NONNULL_BEGIN

@interface RptqDatabaseSchemaField : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "RptqDatabaseSchemaField+CoreDataProperties.h"

#endif
