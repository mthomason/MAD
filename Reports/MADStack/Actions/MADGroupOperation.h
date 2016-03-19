//
//  MADGroupOperation.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADGroupOperation_h
#define MAD_Designer_MADGroupOperation_h

#import "MADOperation.h"

@class NSOperation;

@interface MADGroupOperation : MADOperation

    - (instancetype)initWithOperations:(NSArray <__kindof NSOperation *> *)operations;
    - (void)addOperation:(NSOperation *)operation;
    - (void)aggregateError:(NSError *)error;
    - (void)operationDidFinish:(NSOperation *)operation withErrors:(NSArray *)errors;

@end

#endif
