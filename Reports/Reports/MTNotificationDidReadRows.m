//
//  MTNotificationDidReadRows.m
//  MAD
//
//  Created by Michael Thomason on 6/12/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTNotificationDidReadRows.h"

NSString * const MTNotificationDidReadRowsName = @"MTNotificationDidReadRows";
NSString * const MTDatabaseNumberOfRowsReadKey = @"MTDatabaseNumberOfRowsReadKey";

static const NSInteger RowIntervalInital = 7;

@interface MTNotificationDidReadRows ()

@property (nonatomic, assign) NSInteger rowInterval;

@end

@implementation MTNotificationDidReadRows

static MTNotificationDidReadRows *sharedSingleton = nil;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSingleton = [[super allocWithZone:NULL] init];
        [sharedSingleton initalizeRowInterval];
    });
}

+ (MTNotificationDidReadRows *)sharedObject {
    return sharedSingleton;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [self sharedObject];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (void)initalizeRowInterval {
    [self setRowInterval:RowIntervalInital];
}

- (NSDictionary *)parametersWithNumberOfRows:(NSInteger)row {
    NSNumber *rowCounterWrapper = @(row);
    return @{
             MTDatabaseNumberOfRowsReadKey : rowCounterWrapper,
             };
}

- (void)database:(id)database readRow:(NSUInteger)row {
    if (row % self.rowInterval == 0) {
        if (row == 0) [self initalizeRowInterval];
        NSDictionary *parameters = [self parametersWithNumberOfRows:row];
        NSNotification *notification = [NSNotification notificationWithName:MTNotificationDidReadRowsName object:database userInfo:parameters];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
        if (row > self.rowInterval) {
            self.rowInterval = ceil(self.rowInterval * 1.1);
        }
    }
}

@end
