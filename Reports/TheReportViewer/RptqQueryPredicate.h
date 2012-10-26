//
//  RptqQueryPredicate.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/23/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqQuery;

@interface RptqQueryPredicate : NSManagedObject

@property (nonatomic, retain) NSNumber * comparson;
@property (nonatomic, retain) NSString * fieldleftpred;
@property (nonatomic, retain) NSString * fieldrightpred;
@property (nonatomic, retain) RptqQuery *inQuery;

@end
