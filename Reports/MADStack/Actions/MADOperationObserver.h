//
//  MADOperationObserver.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADOperationObserver_h
#define MAD_Designer_MADOperationObserver_h

@class MADOperation, NSOperation;

/**
 The protocol that types may implement if they wish to be notified of significant
 operation lifecycle events.
 */
@protocol MADOperationObserver <NSObject>

/// Invoked immediately prior to the `Operation`'s `execute()` method.
- (void)operationDidStart:(MADOperation *)operation;

/// Invoked when `Operation.produceOperation(_:)` is executed.
- (void)operation:(MADOperation *)operation didProduceOperation:(NSOperation *)newOperation;

/**
 Invoked as an `Operation` finishes, along with any errors produced during
 execution (or readiness evaluation).
 */
- (void)operationDidFinish:(MADOperation *)operation errors:(NSArray *)errors;

@end

#endif /* MADOperationObserver_h */
