//
//  MADOperationConditionSupport.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/16/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationConditionResult.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSKeyValueCoding.h>
#import <MADFoundation/MADErrorUserInfo.h>
#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationCondition.h>
#import <MADFoundation/MADOperationConditionResult.h>
#import <MADFoundation/NSError+MADOperationErrors.h>

NSString * MADOperationConditionKey = @"OperationCondition";

@interface MADOperationConditionResult ()

    @property (nonatomic, assign) BOOL isSucceed;
    @property (nonatomic, strong) NSError * error;

@end

@implementation MADOperationConditionResult

+ (instancetype)newOperationConditionResultSatisfied {
    return [self newOperationConditionResultIsSucceed:YES error:nil];
}

+ (instancetype)newOperationConditionResult:(BOOL)satisfied {
    return [self newOperationConditionResult:satisfied
                                        name:NSStringFromClass(self.class)];
}

+ (instancetype)newOperationConditionResult:(BOOL)satisfied name:(NSString *)name {
    id operationCondition;
    if (satisfied) {
        operationCondition = [self newOperationConditionResultSatisfied];
    } else {
        operationCondition = [self newOperationConditionResultFailedNotSatisfied:name];
    }
    return operationCondition;
}

+ (instancetype)newOperationConditionResultFailedNotSatisfied:(NSString *)name {
    NSString *message = @"Not Satisified";
    MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle: message
                                                                   andMessage: message];
    NSError *error = [errorUserInfo errorWithDomain: name
                                               code: MADConditionFailed];
    return [MADOperationConditionResult newOperationConditionResultFailed:error];
}

+ (instancetype)newOperationConditionResultFailed:(NSError *)error {
    if (error == nil) {
        error = [NSError errorWithDomain:NSStringFromClass(self) code:32874 userInfo:nil];
    }
    return [self newOperationConditionResultIsSucceed:NO error:error];
}

+ (instancetype)newOperationConditionResultIsSucceed:(BOOL)isSucceed error:(NSError *)error {
    MADOperationConditionResult *newResult = [self new];
    newResult.isSucceed = isSucceed;
    newResult.error = error;
    return newResult;
}

- (void)dealloc { }

- (instancetype)init {
    if (self = [super init]) {

    }
    return self;
}

- (NSError *)error {
    if (!_isSucceed){
        return _error;
    } else {
        return nil;
    }
}
/*
+ (void)evaluateConditions:(NSArray *)conditions operation:(MADOperation *)operation
                completion:(void(^)(NSArray * errors))completion {
    // Check conditions.
    dispatch_group_t conditionGroup = dispatch_group_create();
    
    //array of OperationConditionResult
    NSMutableArray * results = [NSMutableArray arrayWithCapacity:conditions.count];
    
    // Ask each condition to evaluate and store its result in the "results" array.
    for (NSObject <MADOperationCondition> *condition in conditions) {

        dispatch_group_enter(conditionGroup);
        MADOperationConditionResult * result = [condition evaluateForOperation: operation];
        [results addObject:result];
        dispatch_group_leave(conditionGroup);

    }
    
    // After all the conditions have evaluated, this block will execute.
    dispatch_group_notify(conditionGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        
        // Aggregate the errors that occurred, in order.
        NSPredicate *hasError = [NSPredicate predicateWithFormat:@"error != nil"];
        NSArray *resultsWithError = [results filteredArrayUsingPredicate:hasError];
        NSArray *failures = [resultsWithError valueForKeyPath:@"error"];
        
         // If any of the conditions caused this operation to be cancelled, check for that.
        if (operation.isCancelled) {
            NSError *failure = [NSError errorWithCode:MADConditionFailed];
            failures = [failures arrayByAddingObject: failure];
        }
        
        if (completion) {
            NSArray *a = [[NSArray alloc] initWithArray:failures];
            completion(a);
        }
    });
}
*/
+ (void)evaluateConditions:(NSArray *)conditions operation:(MADOperation *)operation completion:(void(^)(NSArray * errors))completion {
    // Check conditions.
    dispatch_group_t conditionGroup = dispatch_group_create();
    
    //array of OperationConditionResult
    NSMutableArray * results = [NSMutableArray arrayWithCapacity:conditions.count];
    
    // Ask each condition to evaluate and store its result in the "results" array.
    [conditions enumerateObjectsUsingBlock:^(NSObject <MADOperationCondition> * condition, NSUInteger idx, BOOL *stop) {
        
        dispatch_group_enter(conditionGroup);
        [condition evaluateForOperation:operation completion:^(MADOperationConditionResult * result) {
            
            [results addObject: result];
            dispatch_group_leave(conditionGroup);
        }];
    }];
    
    // After all the conditions have evaluated, this block will execute.
    dispatch_group_notify(conditionGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        // Aggregate the errors that occurred, in order.
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"error != nil"];
        NSArray * failures = [[results filteredArrayUsingPredicate:predicate] valueForKeyPath:@"error"];
        
        /*
         If any of the conditions caused this operation to be cancelled,
         check for that.
         */
        if (operation.isCancelled) {
            NSError *error = [NSError errorWithCode:MADConditionFailed];
            failures = [failures arrayByAddingObject: error];
        }
        if (completion) {
            completion(failures);
        }
    });
}

@end
