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

@interface MADMutualExclusiveCondition()

    @property (nonatomic, strong) NSString *className;

@end

@implementation MADMutualExclusiveCondition

+ (instancetype)newMutualExclusiveConditionAlertMutex {
    Class acClass = [UIAlertController class];
    return [MADMutualExclusiveCondition newMutualExclusiveConditionForClass:acClass];
}

+ (instancetype)newMutualExclusiveConditionViewControllerMutex {
    Class vcClass = [UIViewController class];
    return [MADMutualExclusiveCondition newMutualExclusiveConditionForClass:vcClass];
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
    completion([MADOperationConditionResult satisfied]);
}

@end
