//
//  RptqQueryPredicate.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

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
