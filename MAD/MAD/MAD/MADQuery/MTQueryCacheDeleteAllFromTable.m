//
//  MTQueryCacheDeleteAllFromTable.m
//  MAD
//
//  Created by Michael Thomason on 4/23/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryCacheDeleteAllFromTable.h"
#import <Foundation/NSString.h>
#import <MAD/MTDatabase.h>

@interface MTQueryCacheDeleteAllFromTable ()

@property (nonatomic, copy) NSString *tableName;

@end

@implementation MTQueryCacheDeleteAllFromTable

- (instancetype)initWithObject:(id)object {
    if (self = [super init]) {
        
        NSString *tableName = object;
        self.tableName = tableName;
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    NSString * __autoreleasing sql = [NSString stringWithFormat:@"DELETE FROM %@", self.tableName];
    return sql;
}

- (BOOL)returnsResults { return NO; }

@end
