//
//  MADExclusivityController.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADExclusivityController.h"
#import <os/log.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <MADFoundation/MADOperation.h>

static id _sharedInstance;

@implementation MADExclusivityController {
    dispatch_queue_t _serialQueue;
    NSMutableDictionary * _operations;
}

+ (instancetype)sharedExclusivityController {
    
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (void)dealloc {
    NSAssert(NO, @"Don't dealloc the singleton.");
}

- (instancetype)init {
    
    if (_sharedInstance) return nil;
    
    if (self = [super init]){
        _serialQueue = dispatch_queue_create("Operations.ExclusivityController", DISPATCH_QUEUE_SERIAL);
        _operations = [[NSMutableDictionary alloc] init];
    }
    return self;

}

/// Registers an operation as being mutually exclusive
- (void)addOperation:(MADOperation *)operation categories:(NSArray */*[String]*/)categories {
    /*
     This needs to be a synchronous operation.
     If this were async, then we might not get around to adding dependencies
     until after the operation had already begun, which would be incorrect.
     */
    dispatch_sync(_serialQueue, ^{
        for (NSString * category in categories) {
            [self noqueue_addOperation:operation category:category];
        }
    });
}

/// Unregisters an operation from being mutually exclusive.
- (void)removeOperation:(MADOperation *)operation categories:(NSArray */*[String]*/)categories {
    os_log_info(OS_LOG_DEFAULT, "%s", __PRETTY_FUNCTION__);
    dispatch_async(_serialQueue, ^{
        for (NSString * category in categories) {
            [self noqueue_removeOperation:operation category:category];
        }
    });
}

#pragma mark - Operation Management

- (void)noqueue_addOperation:(MADOperation*)operation category:(NSString *)category {
    NSMutableArray *operationsWithThisCategory = _operations[category] ?: @[].mutableCopy;
    
    MADOperation *last = operationsWithThisCategory.lastObject;
    if (last) {
        [operation addDependency:last];
    }
    
    [operationsWithThisCategory addObject:operation];
    _operations[category] = operationsWithThisCategory;

}

- (void)noqueue_removeOperation:(MADOperation*)operation category:(NSString *)category {
    NSMutableArray *matchingOperations = _operations[category];
    if (matchingOperations) {
        [matchingOperations removeObject:operation];
        _operations[category] = matchingOperations;
    }
}

- (id)debugQuicklookObject {
    NSString *title = [[NSString alloc] initWithFormat:@"%@ (%lu)\n", NSStringFromClass(self.class),
                       (unsigned long)_operations.count];
    NSString *debug = [title stringByAppendingString:@"\n\tSerial queue: "];
    debug = [debug stringByAppendingString:_serialQueue.description];
    return debug;
}

@end
