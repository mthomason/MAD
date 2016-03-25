//
//  MADNotificationDidReadRows.m
//  MAD
//
//  Created by Michael Thomason on 6/12/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADNotificationDidReadRows.h"
#import <Foundation/NSValue.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSOperation.h>
#import <dispatch/once.h>
#import <math.h>

NSString * const MADNotificationDidReadRowsName = @"MADNotificationDidReadRows";
NSString * const MTDatabaseNumberOfRowsReadKey = @"MTDatabaseNumberOfRowsReadKey";

static const short RowIntervalInital = 7;
static const short RowIntervalInitalMax = 511;

@interface MADNotificationDidReadRows ()

@property (nonatomic, assign) unsigned int rowInterval;

@end

@implementation MADNotificationDidReadRows

static MADNotificationDidReadRows *sharedSingleton = nil;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSingleton = [[super allocWithZone:NULL] init];
        [sharedSingleton initalizeRowInterval];
    });
}

+ (MADNotificationDidReadRows *)sharedObject {
    return sharedSingleton;
}

+ (instancetype)allocWithZone:(NSZone *)zone {
    return [self sharedObject];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return self;
}

- (void)initalizeRowInterval {
    self.rowInterval = RowIntervalInital;
}

- (NSDictionary *)parametersWithNumberOfRows:(NSUInteger)row {
    NSNumber *rowCounterWrapper = @(row);
    NSDictionary * __autoreleasing parameters = @{
                                                  MTDatabaseNumberOfRowsReadKey : rowCounterWrapper,
                                                  };
    return parameters;
}

- (void)database:(id)database readRow:(NSUInteger)row {
    if (row % self.rowInterval == 0) {
        if (row == 0) [self initalizeRowInterval];
 
        if (self.rowInterval < RowIntervalInitalMax && row > self.rowInterval) {
            self.rowInterval = (NSUInteger)ceill((long double)self.rowInterval * 1.19);
        }
        
        NSDictionary *parameters = [self parametersWithNumberOfRows:row];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            NSNotification *notification = [NSNotification notificationWithName: MADNotificationDidReadRowsName
                                                                         object: database
                                                                       userInfo: parameters];
            [[NSNotificationCenter defaultCenter] postNotification:notification];
        }];
    }
}

@end
