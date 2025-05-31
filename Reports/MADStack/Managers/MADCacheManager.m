//
//  MADCacheManager.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/27/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADCacheManager.h"
#import <MADFoundation/MADOperationQueue.h>
#import <Foundation/NSString.h>
#import <dispatch/dispatch.h>
#import <dispatch/once.h>
#include <assert.h>

@interface MADCacheManager ()
@property (nonatomic, strong, readonly) MADOperationQueue *queueForCachingData;
@end

@implementation MADCacheManager

+ (instancetype)sharedManager {
	static id _sharedManager;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedManager = [[self alloc] initPrivate];
		assert(_sharedManager != nil);
	});
	return _sharedManager;
}

- (void)dealloc { }

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
	return [NSString stringWithFormat:@"--%@--\n", [NSStringFromClass([self class]) uppercaseString]];
}

@end
