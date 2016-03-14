//
//  RptqQueryCache.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_AutoGen_RptqQueryCache_h
#define MAD_AutoGen_RptqQueryCache_h

#import <CoreData/NSManagedObject.h>

@class RptqQuery;

@interface RptqQueryCache : NSManagedObject

@property (nonatomic, strong) id cacheDate;
@property (nonatomic, strong) NSData * data;
@property (nonatomic, strong) NSString * filename;
@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) RptqQuery *hasQuery;

@end

#endif
