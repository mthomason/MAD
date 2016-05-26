//
//  MADOperationConditionSupport.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/16/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationConditionResult.h"
#import "MADOperationCondition.h"
#import "MADOperation.h"
#import "NSError+MADOperationErrors.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSKeyValueCoding.h>

NSString * MADOperationConditionKey = @"OperationCondition";

@interface MADOperationConditionResult ()

    @property (nonatomic, assign) BOOL isSucceed;
    @property (nonatomic, strong) NSError * error;

@end

@implementation MADOperationConditionResult

+ (instancetype)newOperationConditionResultSatisfied {
    return [self newOperationConditionResultIsSucceed:YES error:nil];
}

+ (instancetype)newOperationConditionResultFailed:(NSError *)error {
    return [self newOperationConditionResultIsSucceed:NO error:error];
}

+ (instancetype)newOperationConditionResultIsSucceed:(BOOL)isSucceed error:(NSError *)error {
    MADOperationConditionResult *newResult = [self new];
    newResult.isSucceed = isSucceed;
    newResult.error = error;
    return newResult;
}

- (NSError *)error {
    if (!_isSucceed){
        return _error;
    } else {
        return nil;
    }
}

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

@end
