//
//  MTQueryCacheIndexDrop.m
//  MAD
//
//  Created by Michael Thomason on 5/7/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryCacheIndexDrop.h"
#import "MTDatabase.h"
#import "MTDatabaseConnection.h"

@interface MTQueryCacheIndexDrop ()

@property (nonatomic, strong) NSString *indexName;

@end

@implementation MTQueryCacheIndexDrop

- (instancetype)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"MTQueryCacheIndexDrop expects NSDictionary.");
        
        NSNumber *keyIndexName = @(MTQueryCacheIndexDropIndexName);
        
        NSString *indexName = object[keyIndexName];
        [self setIndexName:indexName];
        
        [self setQueryObject:object];
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError * _Nullable *)error {
    return [NSString stringWithFormat:@"DROP INDEX IF EXISTS main.%@", [self indexName]];
}

- (BOOL)returnsResults {
    return NO;
}

@end
