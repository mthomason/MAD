//
//  RptqQueryCache.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqQueryCache_NSManagedObject_h
#define MAD_RptqQueryCache_NSManagedObject_h

#import <CoreData/NSManagedObject.h>

@class NSObject, RptqQuery;

NS_ASSUME_NONNULL_BEGIN

@interface RptqQueryCache : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "RptqQueryCache+CoreDataProperties.h"

#endif
