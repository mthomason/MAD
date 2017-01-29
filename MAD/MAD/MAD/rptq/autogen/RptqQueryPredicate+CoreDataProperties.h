//
//  RptqQueryPredicate+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "RptqQueryPredicate+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqQueryPredicate (CoreDataProperties)

+ (NSFetchRequest<RptqQueryPredicate *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *comparson;
@property (nullable, nonatomic, copy) NSString *fieldleftpred;
@property (nullable, nonatomic, copy) NSString *fieldrightpred;
@property (nullable, nonatomic, copy) NSNumber *identifier;
@property (nullable, nonatomic, retain) RptqQueryField *hasLeftField;
@property (nullable, nonatomic, retain) RptqQueryField *hasRightField;
@property (nullable, nonatomic, retain) RptqQuery *inQuery;

@end

NS_ASSUME_NONNULL_END
