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

@property (nonatomic, retain) NSNumber * comparson;
@property (nonatomic, retain) NSString * fieldleftpred;
@property (nonatomic, retain) NSString * fieldrightpred;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) RptqQueryField *hasLeftField;
@property (nonatomic, retain) RptqQueryField *hasRightField;
@property (nonatomic, retain) RptqQuery *inQuery;

@end
