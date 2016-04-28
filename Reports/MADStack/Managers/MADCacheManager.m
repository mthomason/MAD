//
//  MADCacheManager.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/27/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADCacheManager.h"
#import "MADOperationQueue.h"
#include <assert.h>

@interface MADCacheManager () {
    MADOperationQueue * _queueForCachingData;
}

    @property (nonatomic, strong, readonly) MADOperationQueue *queueForCachingData;

@end

@implementation MADCacheManager

- (void)dealloc {
    assert(NO);
}

+ (instancetype)sharedManager {
    
    static id _sharedManager;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
            _sharedManager = [[self alloc] init];
            assert(_sharedManager != nil);
    });
    
    return _sharedManager;
}


- (instancetype)init {
    if (self == [super init]) {
        self->_queueForCachingData = [[MADOperationQueue alloc] init];
        self->_queueForCachingData.name = @"com.everydayapps.mad.cache";
        self->_queueForCachingData.qualityOfService = NSQualityOfServiceBackground;
        self->_queueForCachingData.maxConcurrentOperationCount = 2;
        assert(self->_queueForCachingData != nil);
    }
    return self;
}

@synthesize queueForCachingData = _queueForCachingData;

- (void)addOperation:(NSOperation *)operation {
    [self.queueForCachingData addOperation:operation];
}

@end
