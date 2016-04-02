//
//  MADRefreshOperation.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADRefreshOperation_h
#define Reports_MADRefreshOperation_h

#import "MADOperation.h"

@class MADocument, MTQuery, MTDatabase, MTDataTableFast;

@interface MADRefreshOperation : MADOperation

    - (instancetype)initWithDocument:(MADocument *)document;
    - (instancetype)initQuery:(MTQuery *)query database:(MTDatabase *)database datatable:(MTDataTableFast *)datatable andCacheUrl:(NSURL *)cacheUrl;

@end

#endif
