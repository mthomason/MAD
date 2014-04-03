//
//  MTQueryTest.m
//  MAD
//
//  Created by Michael Thomason on 4/2/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryTest.h"
#import "MTDatabase.h"
#import "RptqUserCredentals.h"

@implementation MTQueryTest

- (id)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        Class classRptqUserCredentals = [RptqUserCredentals class];
        if ([object isKindOfClass:classRptqUserCredentals]) {
            [self setQueryObject:object];
        }
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    [super getSqlWithError:error];
    
    NSString *key = [[self database] safeIdentifier:@"f1"];
    [[self fieldKeys] addObject:key];
    NSString *sql = [NSString stringWithFormat:@"%@ 255 AS %@", [[self database] selectPart], key];
    return sql;
}

- (void)performQuery:(void (^)(BOOL success, NSError *error, id results))completion {
    
    NSError *error = nil;

    if (error) {
        completion(NO, error, nil);
    } else {
        [[self database] executeQuery:self
                           completion:^(BOOL success, NSError *error, id results) {
                             completion(success, error, results);
                         }];
    }
}

@end
