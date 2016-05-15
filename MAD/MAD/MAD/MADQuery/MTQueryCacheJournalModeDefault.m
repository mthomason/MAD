//
//  MTQueryCacheJournalModeDefault.m
//  MAD
//
//  Created by Michael Thomason on 4/23/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryCacheJournalModeDefault.h"

@interface MTQueryCacheJournalModeDefault ()

@end

@implementation MTQueryCacheJournalModeDefault

- (instancetype)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) { }
    return self;
}

- (NSString *)getSqlWithError:(NSError * __autoreleasing *)error {
    return @"PRAGMA journal_mode=DELETE;";
}

- (BOOL)returnsResults {
    return NO;
}

@end
