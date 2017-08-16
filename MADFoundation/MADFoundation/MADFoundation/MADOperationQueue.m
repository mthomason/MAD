//
//  MADOperationQueue.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationQueue.h"
#import <os/log.h>
#import <Foundation/NSArray.h>
#import <MADFoundation/MADOperation.h>
#import "NSOperation+Advanced.h"
#import "MADBlockObserver.h"
#import "MADOperationCondition.h"
#import "MADExclusivityController.h"

@implementation MADOperationQueue

- (void)dealloc {
    os_log_info(OS_LOG_DEFAULT, "Dealloc %s", NSStringFromClass(self.class).UTF8String);
}

- (void)addOperation:(NSOperation *)operation {

    if ([operation isKindOfClass:[MADOperation class]]) {
    
        MADOperation * op = (MADOperation *)operation;
        typeof(self) __weak weakSelf = self;
        
        // Set up a block delegate. When operation finishes, invoke the delegate method to finish.
        MADBlockObserver *delegate = [[MADBlockObserver alloc] initWithStartHandler: nil
                                                                      produceHandler: ^(MADOperation * oper, NSOperation * newOp) {

            [weakSelf addOperation:newOp];
            
        } finishHandler:^(MADOperation * oper, NSArray * errors) {

            MADOperationQueue *sself = weakSelf;
            [sself.delegate operationQueue:sself operationDidFinish:oper withErrors:errors];
            
        }];
        
        [op addObserver:delegate];
        
        // Extract any dependencies needed by this operation.
        NSMutableArray *dependencies = [[NSMutableArray alloc] initWithCapacity:op.conditions.count];
        for (NSObject <MADOperationCondition> *condition in op.conditions) {

            NSOperation *dependency = [condition dependencyForOperation:op];
            if (dependency) {
                [dependencies addObject:dependency];
            }

        }
        
        for (NSOperation *dependency in dependencies) {
            [op addDependency:dependency];
            [self addOperation:dependency];
        }
        
        // With condition dependencies added, we can now see if this needs dependencies to enforce mutual exclusivity.
        NSMutableArray * concurrencyCategories = [NSMutableArray array];
        for (NSObject <MADOperationCondition> *condition in op.conditions) {

            if ([condition isMutuallyExclusive]) {
                [concurrencyCategories addObject:condition.name];
            }

        }

        if (concurrencyCategories.count) {
        
            // Set up the mutual exclusivity dependencies.
            MADExclusivityController * exclusivityController = [MADExclusivityController sharedExclusivityController];
            
            os_log(OS_LOG_DEFAULT, "Adding operation to exclusivity controller: %s", op.name.UTF8String);
            [exclusivityController addOperation: op categories: concurrencyCategories];
            MADBlockObserver * obs = [[MADBlockObserver alloc] initWithStartHandler: nil
                                                                     produceHandler: nil
                                                                      finishHandler: ^(MADOperation * oper, NSArray * error) {
            
                os_log(OS_LOG_DEFAULT, "Removing operation from exclusivity controller: %s", op.name.UTF8String);
                [exclusivityController removeOperation:oper categories:concurrencyCategories];
                
            }];
            
            [op addObserver:obs];
        }
        
         // Indicate to the operation that we've finished our extra work on it and it's now it a state where it can proceed with evaluating conditions,
         //     if appropriate.

        [op willEnqueue];
        
    } else {

         // For regular `NSOperation`s, we'll manually call out to the queue's delegate we don't want to just capture "operation" because that
         //     would lead to the operation strongly referencing itself and that's the pure definition of a memory leak.
        
        typeof(self) __weak weakSelf = self;
        NSOperation * __weak weakOperation = operation;
        
        [operation addCompletionBlock:^ {
        
            MADOperationQueue *queue = weakSelf;
            id <MADOperationQueueDelegate> sdelegate = queue.delegate;
            
            NSOperation * op = weakOperation;
            if (queue && op) {
                
                if ([sdelegate respondsToSelector:@selector(operationQueue:operationDidFinish:withErrors:)]) {
                
                    [sdelegate operationQueue:queue operationDidFinish:op withErrors:nil];
                    
                }
                
            }
        }];
    }

    id <MADOperationQueueDelegate> sdelegate = self.delegate;
    if ([sdelegate respondsToSelector:@selector(operationQueue:willAddOperation:)]) {
        [sdelegate operationQueue:self willAddOperation:operation];
    }
    
    [super addOperation:operation];
}

- (void)addOperations:(NSArray *)ops waitUntilFinished:(BOOL)wait {
    os_log_info(OS_LOG_DEFAULT, "-[%s %s]", NSStringFromClass(self.class).UTF8String, __FUNCTION__);

    // The base implementation of this method does not call `addOperation()`, so we'll call it ourselves.

    for (NSOperation * op in ops) {
        [self addOperation:op];
    }
    
    if (wait) {
        for (NSOperation * op in ops) {
            [op waitUntilFinished];
        }
    }
}

@end
