//
//  RptqQueryCache.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqQuery;

@interface RptqQueryCache : NSManagedObject

@property (nonatomic, retain) id cacheDate;
@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) RptqQuery *hasQuery;

@end
