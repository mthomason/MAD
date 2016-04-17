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
#import <MAD/MTDatabase.h>
#import "RptqUserCredentals.h"
#import "MTDataTable+Factory.h"
#import <MAD/MTDatabaseConnection.h>

@interface MTQueryTest ()

@end

@implementation MTQueryTest

@dynamic database;

- (instancetype)initWithObject:(id)object {
    if (self = [super init]) { }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    [super getSqlWithError:error];
    
    NSString *key = [self.database safeIdentifier:@"f1"];
    NSString *sql = [NSString stringWithFormat:@"%@ 255 AS %@", [self.database selectPart], key];
    return sql;
}


@end
