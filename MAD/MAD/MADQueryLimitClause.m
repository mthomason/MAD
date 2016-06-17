//
//  MADQueryLimitClause.m
//  MAD
//
//  Created by Michael Thomason on 6/9/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryLimitClause.h"
#import "MTDatabase.h"
#import <Foundation/NSString.h>

@interface MADQueryLimitClause ()

    @property (nonatomic, readwrite, strong) NSString *sql;

@end

@implementation MADQueryLimitClause

- (instancetype)initWithLimit:(NSUInteger)limit
                  andDatabase:(MTDatabase *)database {
    if (self = [super init]) {
        NSString *limitClause = [database sqlLimitClause: limit];
        self.sql = [[NSString alloc] initWithString: limitClause];
    }
    return self;
}

@end
