//
//  MADOperation.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/11/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADOperation_h
#define MAD_Designer_MADOperation_h

#import <Foundation/NSOperation.h>
#import "MADBlockObserver.h"
#import "MADOperationCondition.h"

@class NSMutableArray<ObjectType>;

typedef NS_ENUM(char, MADOperationState) {
    initialized,
    pending,
    evaluatingConditions,
    ready,
    executing,
    finishing,
    finished,
};

@interface MADOperation : NSOperation

    @property (nonatomic, assign, readonly) MADOperationState state;

    @property (nonatomic, strong) NSMutableArray <__kindof NSObject <MADOperationCondition> *> *conditions;
    @property (nonatomic, strong) NSMutableArray <__kindof NSObject <MADOperationObserver> *> *observers;

    - (void)addObserver:(NSObject <MADOperationObserver> *)observer;
    - (void)addCondition:(NSObject <MADOperationCondition> *)condition;
    - (void)willEnqueue;

    - (void)finish;
    - (void)finish:(NSArray *)errors;
    - (void)finishWithError:(NSError *)error;
    - (void)finished:(NSArray *)errors;
    - (void)finishIfCancelled;
    - (void)execute;
    - (void)produceOperation:(NSOperation *)operation;

@end

#endif
