//
//  MTQueryCache.h
//  MAD
//
//  Created by Michael Thomason on 7/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQuery.h"
#import "MTDatabaseCache.h"

@class MTDatabaseCache;

@interface MTQueryCache : MTQuery

@property (nonatomic, strong, readwrite) MTDatabaseCache *database;

@end
