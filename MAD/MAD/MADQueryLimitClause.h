//
//  MADQueryLimitClause.h
//  MAD
//
//  Created by Michael Thomason on 6/9/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MTDatabase;

@interface MADQueryLimitClause : NSObject

    - (instancetype)initWithLimit:(NSUInteger)limit
                      andDatabase:(MTDatabase *)database;

    @property (nonatomic, readonly, strong) NSString *sql;
    
@end
