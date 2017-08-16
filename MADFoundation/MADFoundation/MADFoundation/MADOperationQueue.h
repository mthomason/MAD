//
//  MADOperationQueue.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADOperationQueue_h
#define MAD_Designer_MADOperationQueue_h

#import <Foundation/NSOperation.h>

@class MADOperation, MADOperationQueue;

// The delegate of an `OperationQueue` can respond to `Operation` lifecycle events by implementing these methods.
//
// In general, implementing `OperationQueueDelegate` is not necessary; you would want to use an `OperationObserver` instead. However, there are a couple of
//    situations where using `OperationQueueDelegate` can lead to simpler code. For example, `GroupOperation` is the delegate of its own internal
//    `OperationQueue` and uses it to manage dependencies.

@protocol MADOperationQueueDelegate <NSObject>
@optional
    - (void)operationQueue:(MADOperationQueue *)operationQueue willAddOperation:(NSOperation *)operation;
    - (void)operationQueue:(MADOperationQueue *)operationQueue operationDidFinish:(NSOperation *)operation withErrors:(NSArray *)errors;
@end

// `OperationQueue` is an `NSOperationQueue` subclass that implements a large number of "extra features" related to the `Operation` class:
//
//      - Notifying a delegate of all operation completion
//      - Extracting generated dependencies from operation conditions
//      - Setting up dependencies to enforce mutual exclusivity

@interface MADOperationQueue : NSOperationQueue
    @property (nonatomic, weak) id <MADOperationQueueDelegate> delegate;
@end

#endif
