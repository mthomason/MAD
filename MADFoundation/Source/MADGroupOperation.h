//
//  MADGroupOperation.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADGroupOperation_h
#define MAD_Designer_MADGroupOperation_h

#import <MADFoundation/MADOperation.h>

@class NSOperation, MADOperationQueue;

NS_ASSUME_NONNULL_BEGIN

@interface MADGroupOperation : MADOperation

@property (nonatomic, strong, readonly) MADOperationQueue *internalQueue;
@property (nonatomic, strong, nullable) NSBlockOperation *finishingOperation;

- (void)addOperations:(NSArray <__kindof NSOperation *> *)operations finishingOperation:(nullable NSBlockOperation *)finishingOperation;
- (void)addOperation:(NSArray<__kindof NSOperation *> *)operation;
- (void)aggregateError:(NSError *)error;
- (void)operationDidFinish:(NSOperation *)operation withErrors:(NSArray<NSError *> *)errors;

@end

NS_ASSUME_NONNULL_END

#endif
