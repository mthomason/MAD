//
//  RptqQueryPredicate.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_AutoGen_RptqQueryPredicate_h
#define MAD_AutoGen_RptqQueryPredicate_h

#import <CoreData/NSManagedObject.h>

@class RptqQuery, RptqQueryField;

@interface RptqQueryPredicate : NSManagedObject

@property (nonatomic, strong) NSNumber * comparson;
@property (nonatomic, strong) NSString * fieldleftpred;
@property (nonatomic, strong) NSString * fieldrightpred;
@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) RptqQueryField *hasLeftField;
@property (nonatomic, strong) RptqQueryField *hasRightField;
@property (nonatomic, strong) RptqQuery *inQuery;

@end

#endif
