//
//  MADQueryCustomSql.m
//  MAD
//
//  Created by Michael Thomason on 4/13/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryCustomNoResults.h"
#import <Foundation/NSException.h>
#import <MADAPI/MADQueryType.h>

@interface MADQueryCustomNoResults ()
    @property (nonatomic, strong) id queryObject;
@end

@implementation MADQueryCustomNoResults

- (instancetype)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[NSString class]], @"MADQueryCustomSql expects NSString.");
        NSString *queryString = [[NSString alloc] initWithString:object];
        self.queryObject = queryString;
        
    }
    return self;
}

- (BOOL)returnsResults {
    return NO;
}

- (MADQueryType)type {
    return MADQueryTypeCustomSql;
}

@end
