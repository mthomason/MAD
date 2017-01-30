//
//  RptqQueryField+CoreDataClass.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqQueryField_h
#define MAD_RptqQueryField_h

#import <CoreData/NSManagedObject.h>

@class RptqDatabaseSchemaField, RptqDocumentElementAggregate, RptqDocumentElementBarcode, RptqDocumentElementLabelDataField, RptqQueryGroup, RptqQueryLinks, RptqQueryPredicate, RptqQuerySort, RptqQueryTable;

NS_ASSUME_NONNULL_BEGIN

@interface RptqQueryField : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "RptqQueryField+CoreDataProperties.h"

#endif
