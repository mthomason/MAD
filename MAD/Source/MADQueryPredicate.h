//
//  MADQueryPredicate.h
//  MAD
//
//  Created by Michael Thomason on 6/9/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTQuery_MADQueryPredicate_h
#define Reports_MTQuery_MADQueryPredicate_h

#import <Foundation/NSObject.h>

@class RptqQueryPredicate, MADDatabase, NSSet <__covariant ObjectType>, NSString;

@interface MADQueryPredicate : NSObject

    - (instancetype)initWithQueryPredicates:(NSSet <RptqQueryPredicate *> *)queryPredicates
                                andDatabase:(MADDatabase *)database;

    @property (nonatomic, readonly, strong) NSString *sql;

@end

#endif
