//
//  RptqQueryPredicate.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/28/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqQuery;

@interface RptqQueryPredicate : NSManagedObject

@property (nonatomic, retain) NSString * predicate;
@property (nonatomic, retain) RptqQuery *inQuery;

@end
