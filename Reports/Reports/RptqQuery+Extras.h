//
//  RptqQuery+Extras.h
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqQuery_Extras_h
#define Reports_RptqQuery_Extras_h

#import "RptqQuery.h"
#import "MTProtocolCompare.h"

@class MTGraph;

@interface RptqQuery (Extras) <MTProtocolCompare>

- (RptqQueryGroup *)firstQueryGroup;

@end

#endif
