//
//  MADOperationConditionSuccess.m
//  MAD Designer
//
//  Created by Michael on 8/17/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationConditionSuccess.h"
#import <Foundation/NSOperation.h>
#import <Foundation/NSArray.h>
#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationConditionResult.h>
#import "MADOperationDatabaseTestConnectionProtocol.h"

@implementation MADOperationConditionSuccess

#pragma mark - Condition

- (NSString *)name {
    return NSStringFromClass(super.class);
}

- (BOOL)isMutuallyExclusive {
    return NO;
}

- (NSOperation *)dependencyForOperation:(MADOperation *)operation {
    return nil;
}

- (void)evaluateForOperation:(MADOperation *)operation completion:(void (^)(MADOperationConditionResult *))completion {
    MADOperationConditionResult *result;
    result = [self evaluateForOperation:operation];
    completion(result);
}

- (BOOL)evaludateForOperationSimple:(MADOperation *)operation {
    NSArray<__kindof NSOperation *> *dependencies = operation.dependencies;
    BOOL result = NO;
    
    if (dependencies.count == 0) {
        result = NO;
        return result;
    }
    
    for (NSOperation *dependency in dependencies) {
        
        if ([dependency conformsToProtocol:@protocol(MADOperationDatabaseTestConnectionProtocol)]) {
            NSObject <MADOperationDatabaseTestConnectionProtocol> *testConnection;
            testConnection = (NSObject <MADOperationDatabaseTestConnectionProtocol> *)dependency;
            if (testConnection) {
                if (testConnection.success) {
                    result = YES;
                } else {
                    result = NO;
                }
                break;
            }
        }
    }
    return result;
}

@end
