//
//  MADOperationConditionDisplayedAlertConfirm.m
//  MAD Designer
//
//  Created by Michael on 8/15/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationConditionDisplayedAlertConfirm.h"
#import <os/log.h>
#import <Foundation/NSArray.h>
#import <MAD/MADErrorUserInfo.h>
#import <MAD/MADOperationHoldsCredentialsProtocol.h>
#import "MADOperation.h"
#import "MADOperationConditionResult.h"
#import "MADOperationConditionDisplayedAlert.h"
#import "NSError+MADOperationErrors.h"

@implementation MADOperationConditionDisplayedAlertConfirm

@synthesize reverseCondition = _reverseCondition;

- (instancetype)init {
    if (self = [super init]) {
        _reverseCondition = NO;
    }
    return self;
}

- (NSString *)name { return NSStringFromClass(self.class); }

- (BOOL)isMutuallyExclusive { return NO; }

- (NSOperation *)dependencyForOperation:(MADOperation *)operation { return nil; }


- (void)evaluateForOperation:(MADOperation *)operation completion:(void (^)(MADOperationConditionResult *))completion {
    MADOperationConditionResult *result;
    result = [self evaluateForOperation:operation];
    completion(result);
}

- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation {
    os_log_info(OS_LOG_DEFAULT, "Evaluate\t%s", operation.description.UTF8String);
    
    NSArray<__kindof NSOperation *> *dependencies = operation.dependencies;
    MADOperationConditionResult *result = nil;
    
    if (dependencies.count == 0) {
        result = [MADOperationConditionResult newOperationConditionResultFailedNotSatisfied:self.name];
        return result;
    }
    
    for (MADOperation *dependency in dependencies) {
        
        if ([dependency conformsToProtocol:@protocol(MADOperationConditionDisplayedAlertProtocol)]) {
            
            BOOL condition = [((NSObject <MADOperationConditionDisplayedAlertProtocol> *)dependency) alertDisplayedAffirmed];
            result = [MADOperationConditionResult newOperationConditionResult: _reverseCondition ? !condition : condition
                                                                         name: self.name];
            break;
            
        } else if ([dependency conformsToProtocol:@protocol(MADOperationHoldsCredentialsProtocol)]) {
            BOOL condition = [((NSObject <MADOperationHoldsCredentialsProtocol> *)dependency) manuallyInputtedCredentials];
            result = [MADOperationConditionResult newOperationConditionResult: _reverseCondition ? !condition : condition
                                                                         name: self.name];
            break;
        }
    }
    return result;
}

@end
