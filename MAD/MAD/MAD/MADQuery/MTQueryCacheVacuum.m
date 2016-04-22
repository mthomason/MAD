//
//  MTQueryCacheVacuum.m
//  MAD
//
//  Created by Michael Thomason on 4/23/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryCacheVacuum.h"
#import "MTDatabaseConnection.h"
#import "MTDatabase.h"

@interface MTQueryCacheVacuum ()
    @property (nonatomic, strong) MTDatabaseConnection *connection;
@end

@implementation MTQueryCacheVacuum

- (instancetype)initWithObject:(id)object {

    if (self = [super init]) {
        NSAssert([object isKindOfClass:[NSDictionary class]],
                        @"MTQueryCacheVacuum expects NSDictionary.");
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    return @"VACUUM";
}

- (BOOL)returnsResults {
    return NO;
}


@end
