//
//  MADQueryLimitClause.h
//  MAD
//
//  Created by Michael Thomason on 6/9/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQuery_MADQueryLimitClause_h
#define Reports_MTQuery_MADQueryLimitClause_h

#import <Foundation/NSObject.h>

@class MTDatabase;

@interface MADQueryLimitClause : NSObject

    - (instancetype)initWithLimit:(NSUInteger)limit
                      andDatabase:(MTDatabase *)database;

    @property (nonatomic, readonly, strong) NSString *sql;
    
@end

#endif
