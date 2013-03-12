//
//  RptqQueryPredicate.h
//  Reports
//
//  Created by Michael Thomason on 3/12/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDatabaseSchemaField, RptqQuery;

@interface RptqQueryPredicate : NSManagedObject

@property (nonatomic, retain) NSNumber * comparson;
@property (nonatomic, retain) NSString * fieldleftpred;
@property (nonatomic, retain) NSString * fieldrightpred;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) RptqDatabaseSchemaField *hasLeftField;
@property (nonatomic, retain) RptqDatabaseSchemaField *hasRightField;
@property (nonatomic, retain) RptqQuery *inQuery;

@end
