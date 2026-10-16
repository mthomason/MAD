//
//  MADExclusivityController.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#import "MADExclusivityController.h"
#import <MADFoundation/MADOperation.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <dispatch/dispatch.h>

static MADExclusivityController *_sharedInstance;

@implementation MADExclusivityController {
	dispatch_queue_t _serialQueue;
	NSMutableDictionary<NSString *, NSMutableArray<MADOperation *> *> *_operations;
}

+ (nonnull instancetype)sharedExclusivityController {
	static dispatch_once_t oncePredicate;
	dispatch_once(&oncePredicate, ^{
		_sharedInstance = [[self alloc] init];
	});
	return _sharedInstance;
}

- (void)dealloc {
	NSAssert(NO, @"Don't dealloc the singleton.");
}

#pragma mark - Initialization

- (instancetype)init {
	if (_sharedInstance) return nil;
	
	if (self = [super init]){
		_serialQueue = dispatch_queue_create("Operations.ExclusivityController", DISPATCH_QUEUE_SERIAL);
		_operations = [NSMutableDictionary dictionary];
	}
	return self;

}

#pragma mark - Operation Management

- (void)addOperation:(MADOperation *)operation categories:(NSArray */*[String]*/)categories {
	/*
	 This needs to be a synchronous operation.
	 If this were async, then we might not get around to adding dependencies
	 until after the operation had already begun, which would be incorrect.
	 */
	dispatch_sync(_serialQueue, ^{
		for (NSString *category in categories) {
			[self noqueue_addOperation:operation category:category];
		}
	});
}

- (void)removeOperation:(MADOperation *)operation
			 categories:(nonnull NSArray<NSString *> *)categories {
	dispatch_async(_serialQueue, ^{
		for (NSString *category in categories) {
			[self noqueue_removeOperation:operation category:category];
		}
	});
}

#pragma mark - Operation Management

- (void)noqueue_addOperation:(nonnull MADOperation *)operation category:(nonnull NSString *)category {
	NSMutableArray<MADOperation *> *operationsWithThisCategory = _operations[category] ?: [NSMutableArray array];

	MADOperation *lastOperation = operationsWithThisCategory.lastObject;
	if (lastOperation) {
		[operation addDependency:lastOperation];
	}

	[operationsWithThisCategory addObject:operation];
	_operations[category] = operationsWithThisCategory;
}

- (void)noqueue_removeOperation:(nonnull MADOperation *)operation category:(nonnull NSString *)category {
	NSMutableArray<MADOperation *> *matchingOperations = _operations[category];
	if (matchingOperations) {
		[matchingOperations removeObject:operation];
		_operations[category] = matchingOperations;
	}
}

#pragma mark - Debugging

- (nonnull id)debugQuicklookObject {
	NSString *title = [[NSString alloc] initWithFormat:@"%@ (%lu)\n", NSStringFromClass(self.class), (unsigned long)_operations.count];
#if __APPLE__
	return [[title stringByAppendingString:@"\n\tSerial queue: "] stringByAppendingString:_serialQueue.description];
#else
	// GNUstep builds libdispatch without Objective-C dispatch objects, so the
	// queue has no description on Linux; its label is the portable equivalent.
	NSString *label = [NSString stringWithUTF8String:dispatch_queue_get_label(_serialQueue)];
	return [[title stringByAppendingString:@"\n\tSerial queue: "] stringByAppendingString:label];
#endif
}

@end
