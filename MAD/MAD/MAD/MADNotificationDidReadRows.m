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
#import <Foundation/NSDate.h>
#import <Foundation/NSException.h>
#import <dispatch/once.h>
#import <math.h>

NSString * const MADNotificationDidReadRowsName = @"MADNotificationDidReadRows";
NSString * const MADDatabaseNumberOfRowsReadKey = @"MADDatabaseNumberOfRowsReadKey";

@interface MADNotificationDidReadRows ()
    @property (nonatomic, copy) NSDate *lastUpdate;
@end

@implementation MADNotificationDidReadRows

static MADNotificationDidReadRows *_sharedSingleton = nil;

- (void)dealloc {
    NSAssert(NO, @"Don't dealloc the singleton.");
}

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedSingleton = [[super allocWithZone:NULL] init];
        NSDate *lastUpdate = [NSDate date].copy;
        _sharedSingleton.lastUpdate = lastUpdate;
    });
}

+ (MADNotificationDidReadRows *)sharedObject {
    return _sharedSingleton;
}

+ (instancetype)allocWithZone:(NSZone *)zone {
    return [self sharedObject];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return self;
}

- (void)database:(id)database readRow:(NSUInteger)row {
    if (fabs(self.lastUpdate.timeIntervalSinceNow) > 1.0/60.0) {
        NSDate *lastUpdate = [NSDate date].copy;
        self.lastUpdate = lastUpdate;
        
        NSNumber *rowCounterWrapper = [[NSNumber alloc] initWithUnsignedInteger: row];
        NSDictionary * parameters = [[NSDictionary alloc] initWithObjectsAndKeys:rowCounterWrapper, MADDatabaseNumberOfRowsReadKey, nil];

        NSNotification *notification = [NSNotification notificationWithName: MADNotificationDidReadRowsName object: database userInfo: parameters];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }
}

@end
