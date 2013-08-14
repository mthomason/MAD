//
//  RptqQuery+Extras.h
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqQuery_Extras_h
#define Reports_RptqQuery_Extras_h

#import "RptqQuery.h"
#import "RptqDatabase.h"
#import "MTDatabase.h"
#import "MTGraph.h"
#import "MTProtocolCompare.h"

@interface RptqQuery (Extras) <MTProtocolCompare>

+ (MTGraph *)graphForQuery:(RptqQuery *)query;

- (RptqQueryGroup *)firstQueryGroup;

@end

#endif
