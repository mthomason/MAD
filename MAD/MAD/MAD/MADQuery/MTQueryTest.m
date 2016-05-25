//
//  MTQueryTest.m
//  MAD
//
//  Created by Michael Thomason on 4/2/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryTest.h"
#import "MTDatabase.h"
#import <Foundation/NSString.h>

@implementation MTQueryTest

@dynamic database;

- (instancetype)initWithObject:(id)object {
    if (self = [super init]) { }
    return self;
}

- (NSString *)getSqlWithError:(NSError * __autoreleasing *)error {
    [super getSqlWithError:error];
    
    MADSafeQueryField *key = [self.database newSafeIdentifier:@"f1"];
    NSString *selectPart = [self.database selectPart];
    NSString *sql = [[NSString alloc] initWithFormat:@"%@ 255 AS %@", selectPart, key];
    return sql;
}


@end
