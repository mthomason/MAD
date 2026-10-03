//
//  RptqQuerySort.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_RptqQuerySort_NSManagedObject_h
#define MAD_RptqQuerySort_NSManagedObject_h

#import "RptqObject.h"

@class RptqQuery, RptqQueryField;

NS_ASSUME_NONNULL_BEGIN

@interface RptqQuerySort : RptqObject

@end

@interface RptqQuerySort (CoreDataProperties)

@property (nonatomic) int64_t identifier;
@property (nonatomic) BOOL ascending;
@property (nullable, nonatomic, retain) RptqQueryField *hasField;
@property (nullable, nonatomic, retain) RptqQuery *inQuery;

@end

NS_ASSUME_NONNULL_END

#endif
