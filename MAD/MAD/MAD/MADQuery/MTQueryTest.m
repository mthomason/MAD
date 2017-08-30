//
//  MTQueryTest.m
//  MAD
//
//  Created by Michael Thomason on 4/2/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryTest.h"
#import <MADFoundation/MADDataProtocol.h>
#import <MADAPI/MTDatabase.h>
#import <Foundation/NSString.h>
#import <MADAPI/MADQueryType.h>

@implementation MTQueryTest

@dynamic database;

- (instancetype)initWithObject:(id)object {
    if (self = [super init]) { }
    return self;
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {
    [super getSql:error];
    MTDatabase *database = self.database;
    MADSafeQueryField *key = [database newSafeIdentifier:@"f1"];
    NSString *selectPart = [database selectPart];
    NSString *sql = [[NSString alloc] initWithFormat:@"%@ 255 AS %@", selectPart, key];
    return sql;
}

- (MADQueryType)type {
    return MADQueryTypeConnectionTest;
}

@end
