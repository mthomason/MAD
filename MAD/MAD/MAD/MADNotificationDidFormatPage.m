//
//  MADNotificationDidFormatPage.m
//  MAD
//
//  Created by Michael Thomason on 7/11/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADNotificationDidFormatPage.h"
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSException.h>
#import <dispatch/once.h>
#import <math.h>

NSString * const MADNotificationDidFormatPagesName = @"MADNotificationDidFormatPages";
NSString * const MTDatabaseNumberOfPagesFormattedKey = @"MTDatabaseNumberOfPagesFormattedKey";

@implementation MADNotificationDidFormatPage {
    NSUInteger _pageInterval;
    NSUInteger _pageIntervalInital;
    NSUInteger _pageIntervalInitalMax;
}

static MADNotificationDidFormatPage *_sharedSingleton = nil;

- (void)dealloc {
    NSAssert(NO, @"Don't dealloc the singleton.");
}

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedSingleton = [[super allocWithZone:NULL] init];
    });
}

- (instancetype)init {
    if (self = [super init]) {
        _pageIntervalInital = 1;
        _pageIntervalInitalMax = 7;
        _pageInterval = _pageIntervalInital;
    }
    return self;
}

+ (MADNotificationDidFormatPage *)sharedObject {
    return _sharedSingleton;
}

+ (instancetype)allocWithZone:(NSZone *)zone {
    return [self sharedObject];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSDictionary <NSString *, NSNumber *> *)parametersWithNumberOfPages:(NSUInteger)pages {
    NSNumber *pageCounterWrapper = [[NSNumber alloc] initWithUnsignedInteger: pages];
    NSDictionary *parameters = [[NSDictionary alloc] initWithObjectsAndKeys:
                                pageCounterWrapper, MTDatabaseNumberOfPagesFormattedKey, nil];
    return parameters;
}


- (void)reportFormatter:(MADReportFormatter *)reportFormatter formattedPage:(NSUInteger)page {
    if (page % _pageInterval == 0) {
        if (page == 0) _pageInterval = _pageIntervalInital;
        NSDictionary <NSString *, NSNumber *> *parameters;
        parameters = [self parametersWithNumberOfPages:page];
        NSNotification *notification;
        notification = [NSNotification notificationWithName:MADNotificationDidFormatPagesName
                                                     object:reportFormatter userInfo:parameters];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
        if (_pageInterval < _pageIntervalInitalMax) {
            if (page > _pageInterval) {
                _pageInterval = (unsigned long)ceil(_pageInterval * 1.1);
            }
        }
    }
}

@end
