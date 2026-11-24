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

@class RptqQueryPredicate, RptqQueryField, MADDatabase, NSSet <__covariant ObjectType>, NSString;

@interface MADQueryPredicate : NSObject

    - (instancetype)initWithQueryPredicates:(NSSet <RptqQueryPredicate *> *)queryPredicates
                                andDatabase:(MADDatabase *)database;

    // A field resolver maps a logical field to the SQL column expression the WHERE
    // clause must reference.  nil keeps the ordinary "<alias>.<field>" spelling; a
    // composer hands one in that spells a field as "src0.<physical>" or
    // "src1.<physical>" against the attached input it came from.  The comparison and
    // value-handling behaviour is identical either way.
    - (instancetype)initWithQueryPredicates:(NSSet <RptqQueryPredicate *> *)queryPredicates
                              fieldResolver:(NSString * _Nullable (^)(RptqQueryField *field))fieldResolver
                                andDatabase:(MADDatabase *)database;

    @property (nonatomic, readonly, strong) NSString *sql;

@end

#endif
