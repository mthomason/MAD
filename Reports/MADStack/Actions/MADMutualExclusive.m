//
//  MADMutualExclusive.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/23/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADMutualExclusive.h"
#import <UIKit/UIViewController.h>
#import <UIKit/UIAlertController.h>
#import <UIKit/UIAlert.h>
#import "MADOperation.h"
#import "MADOperationConditionResult.h"

#import <os/log.h>

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
    os_log_info(OS_LOG_DEFAULT, "%s", __PRETTY_FUNCTION__);
    return YES;
}

- (NSOperation *)dependencyForOperation:(MADOperation *)operation { return nil; }

- (void)evaluateForOperation:(MADOperation *)operation completion:(void (^)(MADOperationConditionResult *))completion {
    os_log_info(OS_LOG_DEFAULT, "%s\t%s", __PRETTY_FUNCTION__, operation.description.UTF8String);
    MADOperationConditionResult *result;
    result = [MADOperationConditionResult newOperationConditionResultSatisfied];
    completion(result);
}

- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation {
    os_log_info(OS_LOG_DEFAULT, "%s\t%s", __PRETTY_FUNCTION__, operation.description.UTF8String);
    MADOperationConditionResult *result = [MADOperationConditionResult newOperationConditionResultSatisfied];
    return result;
}

@end
