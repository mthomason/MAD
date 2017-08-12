//
//  MADOperationConditionTestConnectionSuccess.m
//  MAD Designer
//
//  Created by Michael on 8/12/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationConditionTestConnectionSuccess.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSOperation.h>
#import <MAD/MADErrorUserInfo.h>
#import "MADOperation.h"
#import "MADOperationDatabaseTestConnectionProtocol.h"
#import "NSError+MADOperationErrors.h"
#import "MADOperationConditionResult.h"
#import "MADOperationConditionResult.h"


@implementation MADOperationConditionTestConnection

#pragma mark - Condition

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

- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation {
   return nil;
}

@end

@implementation MADOperationConditionTestConnectionSuccess

- (NSString *)name {
    return NSStringFromClass(self.class);
}

#pragma mark - Condition

- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation {
    MADOperationConditionResult *result;
    if ([super evaludateForOperationSimple:operation]) {
        result = [MADOperationConditionResult newOperationConditionResultSatisfied];
    } else {
        MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:@"Not Satisified"
                                                                       andMessage:@"Test connection failed."];
        NSError *error = [errorUserInfo errorWithDomain:self.name code:MADConditionFailed];
        result = [MADOperationConditionResult newOperationConditionResultFailed: error];
    }
    return result;
}

@end

@implementation MADOperationConditionTestConnectionFailuare

- (NSString *)name {
    return NSStringFromClass(self.class);
}

#pragma mark - Condition

- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation {
    MADOperationConditionResult *result;
    if ([super evaludateForOperationSimple:operation]) {
        MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:@"Not Satisified"
                                                                       andMessage:@"Test connection was successful."];
        NSError *error = [errorUserInfo errorWithDomain:self.name code:MADConditionFailed];
        result = [MADOperationConditionResult newOperationConditionResultFailed: error];
    } else {
        result = [MADOperationConditionResult newOperationConditionResultSatisfied];
    }
    return result;
}

@end
