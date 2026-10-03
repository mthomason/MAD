//
//  RptqQueryPredicate.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_RptqQueryPredicate_NSManagedObject_h
#define MAD_RptqQueryPredicate_NSManagedObject_h

#import "RptqObject.h"

@class RptqQuery, RptqQueryField;

NS_ASSUME_NONNULL_BEGIN

@interface RptqQueryPredicate : RptqObject

@end

@interface RptqQueryPredicate (CoreDataProperties)

@property (nonatomic) int16_t comparson;
@property (nonatomic) int64_t identifier;
@property (nullable, nonatomic, copy) NSString *leftFieldID;
@property (nullable, nonatomic, copy) NSString *rigthFieldID;
@property (nullable, nonatomic, retain) RptqQuery *inQuery;
@property (nullable, nonatomic, retain) RptqQueryField *hasLeftField;
@property (nullable, nonatomic, retain) RptqQueryField *hasRightField;

@end

NS_ASSUME_NONNULL_END

#endif
