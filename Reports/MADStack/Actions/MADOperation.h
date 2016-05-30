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


@class NSMutableArray<ObjectType>;

typedef NS_ENUM(char, MADOperationState) {
    MADOperationStateInitialized,
    MADOperationStatePending,
    MADOperationStateEvaluatingConditions,
    MADOperationStateReady,
    MADOperationStateExecuting,
    MADOperationStateFinishing,
    MADOperationStateFinished,
};

@protocol MADOperationCondition;
@protocol MADOperationObserver;

typedef NSMutableArray <__kindof NSObject <MADOperationCondition> *> MADMutableOperationConditions;
typedef NSMutableArray <__kindof NSObject <MADOperationObserver> *> MADMutableOperationObservers;

@interface MADOperation : NSOperation

    @property (nonatomic, assign, readwrite) NSUInteger tag;
    @property (nonatomic, assign, readonly) MADOperationState state;

    @property (nonatomic, strong) MADMutableOperationConditions *conditions;
    @property (nonatomic, strong) MADMutableOperationObservers *observers;

    - (void)addObserver:(NSObject <MADOperationObserver> *)observer;
    - (void)addCondition:(NSObject <MADOperationCondition> *)condition;
    - (void)willEnqueue;

    - (void)finish;
    - (void)finish:(NSArray *)errors;
    - (void)finishWithError:(NSError *)error;
    - (void)finished:(NSArray *)errors;
    - (void)execute;
    - (void)produceOperation:(NSOperation *)operation;

@end

#endif
