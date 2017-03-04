//
//  MADQueryPredicate.h
//  MAD
//
//  Created by Michael Thomason on 6/9/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQuery_MADQueryPredicate_h
#define Reports_MTQuery_MADQueryPredicate_h

#import <Foundation/NSObject.h>

@class RptqQueryPredicate, MTDatabase, NSSet <__covariant ObjectType>, NSString;

@interface MADQueryPredicate : NSObject

    - (instancetype)initWithQueryPredicates:(NSSet <RptqQueryPredicate *> *)queryPredicates
                                andDatabase:(MTDatabase *)database;

    @property (nonatomic, readonly, strong) NSString *sql;

@end

#endif
