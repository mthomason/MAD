//
//  MTQueryCacheJournalModeOverride.m
//  MAD
//
//  Created by Michael Thomason on 4/23/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryCacheJournalModeOverride.h"

@interface MTQueryCacheJournalModeOverride ()

//- (instancetype)initWithObject:(id)object NS_DESIGNATED_INITIALIZER;

@end

@implementation MTQueryCacheJournalModeOverride

- (instancetype)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) { }
    return self;
}

- (NSString *)getSqlWithError:(NSError * _Nullable *)error {
    return @"PRAGMA journal_mode=WAL;";
}

- (BOOL)returnsResults {
    return NO;
}

@end
