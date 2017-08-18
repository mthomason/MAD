//
//  MADOperation.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/11/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADOperation_h
#define MAD_Designer_MADOperation_h

#import <Foundation/NSOperation.h>


@class NSMutableArray<ObjectType>;

typedef NS_ENUM(NSInteger, MADOperationState) {
    MADOperationStateInitialized,
    MADOperationStatePending,
    MADOperationStateEvaluatingConditions,
    MADOperationStateReady,
    MADOperationStateExecuting,
    MADOperationStateFinishing,
    MADOperationStateFinished,
};

static inline const char *MADStringOperationState(MADOperationState);
static inline const char *MADStringOperationState(MADOperationState state) {
    switch (state) {
        case MADOperationStateInitialized:
            return "Initalized";
            break;
        case MADOperationStatePending:
            return "Pending";
            break;
        case MADOperationStateEvaluatingConditions:
            return "Eonditions";
            break;
        case MADOperationStateReady:
            return "Ready";
            break;
        case MADOperationStateExecuting:
            return "Executing";
            break;
        case MADOperationStateFinishing:
            return "Finishing";
            break;
        case MADOperationStateFinished:
            return "Finished";
            break;
            
        default:
            return nil;
            break;
    }
};

@protocol MADOperationCondition;
@protocol MADOperationObserver;

typedef NSMutableArray <__kindof NSObject <MADOperationCondition> *> MADMutableOperationConditions;
typedef NSMutableArray <__kindof NSObject <MADOperationObserver> *> MADMutableOperationObservers;

@interface MADOperation : NSOperation

    @property (atomic, assign, readwrite) NSUInteger identifier;
    @property (atomic, assign, readonly) MADOperationState state;

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
    - (void)cleanup;

@end

#endif
