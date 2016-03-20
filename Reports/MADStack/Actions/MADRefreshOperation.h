//
//  MADRefreshOperation.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADOperation.h"

@class MTQuery, MTDatabase, MTDataTable;

@interface MADRefreshOperation : MADOperation

- (instancetype)initQuery:(MTQuery *)query database:(MTDatabase *)database datatable:(MTDataTable *)datatable andCacheUrl:(NSURL *)cacheUrl;

@end
