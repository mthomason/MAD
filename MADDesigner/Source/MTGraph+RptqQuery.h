//
//  MTGraph+RptqQuery.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/3/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MTGraph_RptqQuery_h
#define MAD_Designer_MTGraph_RptqQuery_h

#import <MADDataStructures/MTGraph.h>
#import <MAD/RptqStoreContext.h>

@class RptqQuery, MADModelQuery, RptqStoreContext;

@interface MTGraph (RptqQuery)

	- (instancetype)initWithQuery:(RptqQuery *)query;
	- (instancetype)initWtthQueryID:(MADModelQuery *)query;
	- (instancetype)initWithQueryID:(int64_t)queryID managedObjectContext:(RptqStoreContext *)context;

@end

#endif
