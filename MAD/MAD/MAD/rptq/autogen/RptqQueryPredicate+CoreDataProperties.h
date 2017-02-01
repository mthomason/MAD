//
//  RptqQueryPredicate+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqQueryPredicate_CoreDataProperties_h
#define MAD_RptqQueryPredicate_CoreDataProperties_h

#import "RptqQueryPredicate.h"
#import <CoreData/NSFetchRequest.h>

NS_ASSUME_NONNULL_BEGIN

@interface RptqQueryPredicate (CoreDataProperties)

+ (NSFetchRequest<RptqQueryPredicate *> *)fetchRequest;

@property (nonatomic) int16_t comparson;
@property (nullable, nonatomic, copy) NSString *leftFieldID;
@property (nullable, nonatomic, copy) NSString *rightFieldID;
@property (nonatomic) int64_t identifier;
@property (nullable, nonatomic, retain) RptqQueryField *hasLeftField;
@property (nullable, nonatomic, retain) RptqQueryField *hasRightField;
@property (nullable, nonatomic, retain) RptqQuery *inQuery;

@end

NS_ASSUME_NONNULL_END

#endif
