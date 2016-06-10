//
//  MADQueryPredicate.h
//  MAD
//
//  Created by Michael Thomason on 6/9/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RptqQueryPredicate;
@class MTDatabase;

@interface MADQueryPredicate : NSObject

    - (instancetype)initWithQueryPredicates:(NSSet <RptqQueryPredicate *> *)queryPredicates
                                andDatabase:(MTDatabase *)database;

    @property (nonatomic, readonly, strong) NSString *sql;

@end
