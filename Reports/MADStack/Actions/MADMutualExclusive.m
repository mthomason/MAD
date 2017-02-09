//
//  MADMutualExclusive.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/23/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADMutualExclusive.h"
#import <UIKit/UIViewController.h>
#import <UIKit/UIAlertController.h>
#import <UIKit/UIAlert.h>

#import "MADOperationConditionResult.h"

@interface MADMutualExclusiveCondition()

    @property (nonatomic, strong) NSString *className;

@end

@implementation MADMutualExclusiveCondition

+ (instancetype)newMutualExclusiveConditionAlertMutex {
    return [MADMutualExclusiveCondition newMutualExclusiveConditionForClass:[UIAlertController class]];
}

+ (instancetype)newMutualExclusiveConditionViewControllerMutex {
    return [MADMutualExclusiveCondition newMutualExclusiveConditionForClass:[UIViewController class]];
}

+ (instancetype)newMutualExclusiveConditionForClass:(Class)class {
    MADMutualExclusiveCondition *mutex = [[MADMutualExclusiveCondition alloc] init];
    NSString *className = NSStringFromClass(class);
    mutex.className = className;
    return mutex;
}

#pragma mark - SUBCLASSING

- (NSString *)name { return [NSString stringWithFormat:@"MutuallyExclusive<%@>", self.className]; }

- (BOOL)isMutuallyExclusive {
    return YES;
}

- (NSOperation *)dependencyForOperation:(MADOperation *)operation { return nil; }

- (void)evaluateForOperation:(MADOperation *)operation completion:(void (^)(MADOperationConditionResult *))completion {
    MADOperationConditionResult *result;
    result = [self evaluateForOperation:operation];
    completion(result);
}

- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation {
    MADOperationConditionResult *result = [MADOperationConditionResult newOperationConditionResultSatisfied];
    return result;
}

@end
