//
//  MADNotificationDidFormatPage.m
//  MAD
//
//  Created by Michael Thomason on 7/11/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
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

static const NSInteger PageIntervalInital = 1;
static const NSInteger PageIntervalInitalMax = 7;

@interface MADNotificationDidFormatPage ()

    @property (nonatomic, assign) NSUInteger pageInterval;

@end

@implementation MADNotificationDidFormatPage

static MADNotificationDidFormatPage *sharedSingleton = nil;

- (void)dealloc {
    NSAssert(NO, @"Don't dealloc the singleton.");
}

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSingleton = [[super allocWithZone:NULL] init];
        [sharedSingleton initializeRowInterval];
    });
}

+ (MADNotificationDidFormatPage *)sharedObject {
    return sharedSingleton;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [self sharedObject];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (void)initializeRowInterval {
    self.pageInterval = PageIntervalInital;
}

- (NSDictionary *)parametersWithNumberOfPages:(NSUInteger)pages {
    NSNumber *pageCounterWrapper = [[NSNumber alloc] initWithUnsignedInteger: pages];
    NSDictionary *parameters = [[NSDictionary alloc] initWithObjectsAndKeys:
                                pageCounterWrapper, MTDatabaseNumberOfPagesFormattedKey, nil];
    return parameters;
}


- (void)reportFormatter:(MTReportFormatter *)reportFormatter formattedPage:(NSUInteger)page {
    if (page % self.pageInterval == 0) {
        if (page == 0) [self initializeRowInterval];
        NSDictionary *parameters = [self parametersWithNumberOfPages:page];
        NSNotification *notification;
        notification = [NSNotification notificationWithName:MADNotificationDidFormatPagesName
                                                     object:reportFormatter userInfo:parameters];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
        if (self.pageInterval < PageIntervalInitalMax) {
            if (page > self.pageInterval) {
                self.pageInterval = (unsigned long)ceil(self.pageInterval * 1.1);
            }
        }
    }
}

@end
