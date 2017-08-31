//
//  MTQueryCacheJournalModeDefault.m
//  MAD
//
//  Created by Michael Thomason on 4/23/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryCacheJournalModeDefault.h"
#import <MADAPI/MADQueryType.h>

@interface MADQueryCacheJournalModeDefault ()

@end

@implementation MADQueryCacheJournalModeDefault

- (instancetype)initWithObject:(id)object {
    return self = [super initWithObject:object];
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {
    return @"PRAGMA journal_mode=DELETE;";
}

- (BOOL)returnsResults {
    return NO;
}

- (MADQueryType)type {
    return MADQueryTypeCacheJournalModeDefault;
}

@end
