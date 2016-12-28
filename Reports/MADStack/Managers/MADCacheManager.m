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

@synthesize queueForCachingData = _queueForCachingData;

+ (instancetype)sharedManager {
    
    static id _sharedManager;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] initPrivate];
        assert(_sharedManager != nil);
    });
    
    return _sharedManager;
}

- (void)dealloc {
    assert(NO);
}

- (instancetype)init {
    return [[self class] sharedManager];
}

- (instancetype)initPrivate {
    self = [super init];
    if (self = [super init]) {
        id queue = [[MADOperationQueue alloc] init];
        _queueForCachingData = queue;
        _queueForCachingData.name = @"com.everydayapps.mad.cache";
        _queueForCachingData.qualityOfService = NSQualityOfServiceBackground;
        _queueForCachingData.maxConcurrentOperationCount = 2;
        assert(_queueForCachingData != nil);
    }
    return self;
}

- (void)addOperation:(NSOperation *)operation {
    [self.queueForCachingData addOperation:operation];
}

- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    NSString *classname = NSStringFromClass([self class]);
    id uppercaseClassname = [classname uppercaseString];
    [debug appendFormat:@"--%@--\n", uppercaseClassname];
    return debug;
}

@end
