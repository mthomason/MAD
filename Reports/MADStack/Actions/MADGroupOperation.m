//
//  MADGroupOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADGroupOperation.h"
#import "MADOperationQueue.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>
#import "MADDefer.h"
/**
 A subclass of `Operation` that executes zero or more operations as part of its
 own execution. This class of operation is very useful for abstracting several
 smaller operations into a larger operation. As an example, the `GetEarthquakesOperation`
 is composed of both a `DownloadEarthquakesOperation` and a `ParseEarthquakesOperation`.
 
 Additionally, `GroupOperation`s are useful if you establish a chain of dependencies,
 but part of the chain may "loop". For example, if you have an operation that
 requires the user to be authenticated, you may consider putting the "login"
 operation inside a group operation. That way, the "login" operation may produce
 subsequent operations (still within the outer `GroupOperation`) that will all
 be executed before the rest of the operations in the initial chain of operations.
 */

@interface MADGroupOperation () <MADOperationQueueDelegate>

    @property (nonatomic, strong) NSMutableArray <__kindof NSError *> *aggregatedErrors;

@end

@implementation MADGroupOperation

- (void)dealloc { }

- (void)addOperations:(NSArray <__kindof NSOperation *> *)operations {
    [self addOperations:operations finishingOperation:nil];
}


- (void)addOperations:(NSArray <__kindof NSOperation *> *)operations
   finishingOperation:(NSBlockOperation *)finishingOperation {
    _finishingOperation = finishingOperation;
    if (_internalQueue == nil) {
        _internalQueue = [MADOperationQueue new];
    }
    _internalQueue.suspended = YES;
    _internalQueue.delegate = self;
    for (NSOperation *op in operations){
        [_finishingOperation addDependency:op];
        [_internalQueue addOperation:op];
    }
    //[_internalQueue addOperation:_finishingOperation];
}

- (MADOperationQueue *)internalQueue {
    if (_internalQueue == nil) {
        MADOperationQueue *internalQueue = [MADOperationQueue new];
        internalQueue.suspended = YES;
        internalQueue.delegate = self;
        return _internalQueue = internalQueue;
    } else {
        return _internalQueue;
    }
}

- (void)cancel {
    [self.internalQueue cancelAllOperations];
    [super cancel];
}

- (void)execute {
    self.internalQueue.suspended = NO;
    [self.internalQueue addOperation:self.finishingOperation];
}

- (void)addOperation:(NSOperation *)operation {
    [self.internalQueue addOperation:operation];
}

/**
 Note that some part of execution has produced an error.
 Errors aggregated through this method will be included in the final array
 of errors reported to observers and to the `finished(_:)` method.
 */

- (void)aggregateError:(NSError *)error {
    [self.aggregatedErrors addObject:error];
}

- (void)operationDidFinish:(NSOperation *)operation withErrors:(NSArray *)errors {
    // For use by subclassers.
}

#pragma mark - MADOperationQueueDelegate

- (void)operationQueue:(MADOperationQueue *)operationQueue willAddOperation:(NSOperation *)operation {
    NSAssert(!self.finishingOperation.finished, @"cannot add new operations to a group after the group has completed");

    /*
     Some operation in this group has produced a new operation to execute.
     We want to allow that operation to execute before the group completes,
     so we'll make the finishing operation dependent on this newly-produced operation.
     */
    if (operation != self.finishingOperation) {
        [self.finishingOperation addDependency:operation];
    }

}

-(void)operationQueue:(MADOperationQueue *)operationQueue
   operationDidFinish:(NSOperation *)operation
           withErrors:(NSArray *)errors {
    [self.aggregatedErrors addObjectsFromArray:errors];
    
    if (operation == self.finishingOperation){
        self.internalQueue.suspended = YES;
        [self finishWithError:self.aggregatedErrors.copy];
    } else {
        [self operationDidFinish:operation withErrors:errors];
    }
}

@end
