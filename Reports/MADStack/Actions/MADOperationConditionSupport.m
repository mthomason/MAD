//
//  MADOperationConditionSupport.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/16/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationConditionSupport.h"
#import "MADOperationCondition.h"
#import "MADOperation.h"
#import "NSError+MADOperationErrors.h"

NSString * MADOperationConditionKey = @"OperationCondition";

@interface MADOperationConditionSupport ()

    @property (nonatomic, assign) BOOL isSucceed;
    @property (nonatomic, strong) NSError * error;

@end

@implementation MADOperationConditionSupport

+ (MADOperationConditionSupport *)satisfied {
    return [self isSucceed:YES error:nil];
}

+ (MADOperationConditionSupport *)failed:(NSError *)error {
    return [self isSucceed:NO error:error];
}

+ (MADOperationConditionSupport *)isSucceed:(BOOL)isSucceed error:(NSError *)error {
    MADOperationConditionSupport * newResult = [MADOperationConditionSupport new];
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

+ (void)evaluateConditions:(NSArray *)conditions operation:(MADOperation *)operation completion:(void(^)(NSArray * errors))completion {
    // Check conditions.
    dispatch_group_t conditionGroup = dispatch_group_create();
    
    //array of OperationConditionResult
    NSMutableArray * results = [NSMutableArray arrayWithCapacity:conditions.count];
    
    // Ask each condition to evaluate and store its result in the "results" array.
    [conditions enumerateObjectsUsingBlock:^(NSObject <MADOperationCondition> * condition, NSUInteger idx, BOOL *stop) {
        
        dispatch_group_enter(conditionGroup);
        [condition evaluateForOperation:operation completion:^(MADOperationConditionSupport * result) {
            
            results[idx] = result;
            dispatch_group_leave(conditionGroup);
        }];
    }];
    
    // After all the conditions have evaluated, this block will execute.
    dispatch_group_notify(conditionGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        // Aggregate the errors that occurred, in order.
        NSArray * failures = [[results filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"error != nil"]] valueForKeyPath:@"error"];
        
        /*
         If any of the conditions caused this operation to be cancelled,
         check for that.
         */
        if (operation.isCancelled) {
            failures = [failures arrayByAddingObject: [NSError errorWithCode:MADConditionFailed]];
        }
        if (completion){
            completion(failures);
        }
    });
}

@end
