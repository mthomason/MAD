//
//  MTQueryCacheAggregateFunction.h
//  MAD
//
//  Created by Michael Thomason on 6/1/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryCacheAggregateFunction_h
#define Reports_MTQueryCacheAggregateFunction_h

#import <MADAPI/MTQuery.h>

@interface MTQueryCacheAggregateFunction : MTQuery
    <MADQueryDataBindingProtocol, MADQueryColumnsProtocol>
@end

#endif
