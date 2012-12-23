//
//  RptqQueryPredicate.h
//  Reports
//
//  Created by Michael Thomason on 12/23/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqField, RptqQuery;

@interface RptqQueryPredicate : NSManagedObject

@property (nonatomic, retain) NSNumber * comparson;
@property (nonatomic, retain) NSString * fieldleftpred;
@property (nonatomic, retain) NSString * fieldrightpred;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) RptqField *hasLeftField;
@property (nonatomic, retain) RptqField *hasRightField;
@property (nonatomic, retain) RptqQuery *inQuery;

@end
