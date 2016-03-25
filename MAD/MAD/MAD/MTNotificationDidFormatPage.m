//
//  MTNotificationDidFormatPage.m
//  MAD
//
//  Created by Michael Thomason on 7/11/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTNotificationDidFormatPage.h"
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSValue.h>
#import <dispatch/once.h>
#import <math.h>

NSString * const MTNotificationDidFormatPagesName = @"MTNotificationDidFormatPages";
NSString * const MTDatabaseNumberOfPagesFormattedKey = @"MTDatabaseNumberOfPagesFormattedKey";

static const NSInteger PageIntervalInital = 1;
static const NSInteger PageIntervalInitalMax = 7;

@interface MTNotificationDidFormatPage ()

@property (nonatomic, assign) NSUInteger pageInterval;

@end

@implementation MTNotificationDidFormatPage

static MTNotificationDidFormatPage *sharedSingleton = nil;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSingleton = [[super allocWithZone:NULL] init];
        [sharedSingleton initalizeRowInterval];
    });
}

+ (MTNotificationDidFormatPage *)sharedObject {
    return sharedSingleton;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [self sharedObject];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (void)initalizeRowInterval {
    [self setPageInterval:PageIntervalInital];
}

- (NSDictionary *)parametersWithNumberOfPages:(NSUInteger)pages {
    NSNumber *pageCounterWrapper = @(pages);
    return @{
             MTDatabaseNumberOfPagesFormattedKey : pageCounterWrapper,
             };
}


- (void)reportFormatter:(MTReportFormatter *)reportFormatter formattedPage:(NSUInteger)page {
    if (page % self.pageInterval == 0) {
        if (page == 0) [self initalizeRowInterval];
        NSDictionary *parameters = [self parametersWithNumberOfPages:page];
        NSNotification *notification = [NSNotification notificationWithName:MTNotificationDidFormatPagesName object:reportFormatter userInfo:parameters];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
        if ([self pageInterval] < PageIntervalInitalMax) {
            if (page > self.pageInterval) {
                self.pageInterval = (unsigned long)ceil(self.pageInterval * 1.1);
            }
        }
    }
}

@end
