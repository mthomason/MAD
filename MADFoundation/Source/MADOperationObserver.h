//
//  MADOperationObserver.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADOperationObserver_h
#define MAD_Designer_MADOperationObserver_h

@class NSOperation, MADOperation;

@protocol MADOperationObserver <NSObject>

- (void)operationDidStart:(nonnull MADOperation *)operation;
- (void)operation:(nonnull MADOperation *)operation didProduceOperation:(nonnull NSOperation *)newOperation;
- (void)operationDidFinish:(nonnull MADOperation *)operation errors:(nullable NSArray <NSError *> *)errors;

@end

#endif
