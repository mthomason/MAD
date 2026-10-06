//
//  MADOperation.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/11/16.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADOperation_h
#define MAD_Designer_MADOperation_h

#import <Foundation/NSOperation.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSError.h>

@class NSMutableArray<ObjectType>;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MADOperationState) {
	MADOperationStateInitialized,
	MADOperationStatePending,
	MADOperationStateEvaluatingConditions,
	MADOperationStateReady,
	MADOperationStateExecuting,
	MADOperationStateFinishing,
	MADOperationStateFinished,
};

static inline NSString *NSStringFromMADOperationState(MADOperationState);
static inline NSString *NSStringFromMADOperationState(MADOperationState state) {
	switch (state) {
		case MADOperationStateInitialized: return @"Initialized";
		case MADOperationStatePending: return @"Pending";
		case MADOperationStateEvaluatingConditions: return @"EvaluatingConditions";
		case MADOperationStateReady: return @"Ready";
		case MADOperationStateExecuting: return @"Executing";
		case MADOperationStateFinishing: return @"Finishing";
		case MADOperationStateFinished: return @"Finished";
		default: return @"Unknown";
	}
}

@protocol MADOperationCondition;
@protocol MADOperationObserver;

typedef NSMutableArray <__kindof NSObject <MADOperationCondition> *> MADMutableOperationConditions;
typedef NSMutableArray <__kindof NSObject <MADOperationObserver> *> MADMutableOperationObservers;

@interface MADOperation : NSOperation

	@property (readonly, nonatomic, strong) NSMutableArray <NSError *> *errors;
	@property (atomic, assign, readwrite) NSUInteger identifier;
	@property (atomic, assign, readonly) MADOperationState state;

	@property (nonatomic, strong) MADMutableOperationConditions *conditions;
	@property (nonatomic, strong) MADMutableOperationObservers *observers;

	- (void)addObserver:(nonnull NSObject <MADOperationObserver> *)observer;
	- (void)addObservers:(nonnull NSArray<NSObject<MADOperationObserver> *> *)observers;
	- (void)addCondition:(nonnull NSObject <MADOperationCondition> *)condition;
	- (void)addConditions:(nonnull NSArray<NSObject<MADOperationCondition> *> *)conditions;
	- (void)willEnqueue;

	- (void)finish;
	- (void)finish:(nullable NSArray<NSError *> *)errors;
	- (void)finishWithError:(nullable NSError *)error;
	- (void)finished:(nullable NSArray<NSError *> *)errors;
	- (void)execute;
	- (void)produceOperation:(nonnull NSOperation *)operation;
	- (void)cleanup;

@end

NS_ASSUME_NONNULL_END

#endif
