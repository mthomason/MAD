//
//  MADExclusivityController.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#import "MADExclusivityController.h"
#import <os/log.h>
#import <MADFoundation/MADOperation.h>

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
	return [[title stringByAppendingString:@"\n\tSerial queue: "] stringByAppendingString:_serialQueue.description];
}

@end
