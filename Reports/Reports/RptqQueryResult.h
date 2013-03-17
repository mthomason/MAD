//
//  RptqQueryResult.h
//  Reports
//
//  Created by Michael Thomason on 3/16/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqQueryCache;

@interface RptqQueryResult : NSManagedObject

@property (nonatomic, retain) NSString * fieldname;
@property (nonatomic, retain) NSNumber * rowid;
@property (nonatomic, retain) id value;
@property (nonatomic, retain) RptqQueryCache *inQueryCache;

@end
