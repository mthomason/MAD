//
//  RptqQueryPredicate+CoreDataClass.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqQueryPredicate_NSManagedObject_h
#define MAD_RptqQueryPredicate_NSManagedObject_h

#import <CoreData/NSManagedObject.h>

@class RptqQuery, RptqQueryField;

NS_ASSUME_NONNULL_BEGIN

@interface RptqQueryPredicate : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "RptqQueryPredicate+CoreDataProperties.h"

#endif
