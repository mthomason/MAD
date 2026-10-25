//
//  MADOperationObserver.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADOperationObserver_h
#define MAD_Designer_MADOperationObserver_h

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSError.h>
@class NSOperation, MADOperation;

@protocol MADOperationObserver <NSObject>

- (void)operationDidStart:(nonnull MADOperation *)operation;
- (void)operation:(nonnull MADOperation *)operation didProduceOperation:(nonnull NSOperation *)newOperation;
- (void)operationDidFinish:(nonnull MADOperation *)operation errors:(nullable NSArray <NSError *> *)errors;

@end

#endif
