//
//  RptqQueryCache.h
//  Reports
//
//  Created by Michael Thomason on 12/15/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqQuery;

@interface RptqQueryCache : NSManagedObject

@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) RptqQuery *hasQuery;

@end
