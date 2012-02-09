//
//  RptqQueryPredicate.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqQuery;

@interface RptqQueryPredicate : NSManagedObject

@property (nonatomic, retain) NSNumber * comparson;
@property (nonatomic, retain) NSString * fieldleft;
@property (nonatomic, retain) NSString * fieldright;
@property (nonatomic, retain) NSNumber * numberleft;
@property (nonatomic, retain) NSNumber * numberright;
@property (nonatomic, retain) RptqQuery *inQuery;

@end
