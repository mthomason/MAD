//
//  MADOperationConditionHasCredientals.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationConditionHasResultString.h"
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import "MADOperationConditionHasResultStringResult.h"
#import "MADOperation.h"
#import "NSError+MADOperationErrors.h"
#import "MADKeyChainOperationGet.h"

@interface MADOperationConditionHasResultString ()

    @property (nonatomic, readwrite, copy) NSString *key;

@end

@implementation MADOperationConditionHasResultString

- (instancetype)initWithKey:(NSString *)key {
    if (self = [super init]) {
        self.key = key;
    }
    return self;
}

#pragma mark - Condition
- (NSString *)name {
    return NSStringFromClass(self.class);
}

- (BOOL)isMutuallyExclusive {
    return NO;
}

- (NSOperation *)dependencyForOperation:(MADOperation *)operation {
    return nil;
}

- (void)evaluateForOperation:(MADOperation *)operation
                  completion:(void (^)(MADOperationConditionResult *))completion {
    
    NSArray<__kindof NSOperation *> *dependencies = operation.dependencies;
    
    if (dependencies.count == 0) {
        completion([MADOperationConditionResult failed:nil]);
        return;
    }
    
    MADOperationConditionResult *result = nil;
    
    for (NSOperation *dependency in dependencies) {
        if ([dependency conformsToProtocol:@protocol(MADOperationResultStringProtocol)]) {
            if ([self.key isEqualToString: ((NSObject <MADOperationResultStringProtocol> *) dependency).key]) {
                
                if (((NSObject <MADOperationResultStringProtocol> *) dependency).success) {
                    
                    result = [MADOperationConditionHasResultStringResult satisfied];
                    ((MADOperationConditionHasResultStringResult *)result).result =
                    ((NSObject <MADOperationResultStringProtocol> *) dependency).value;
                    
                } else {
                    result = [MADOperationConditionResult failed:nil];
                }
                break;
            }
        }
    }
    
    if (result != nil) {
        completion(result);
    } else {
        completion([MADOperationConditionResult failed:nil]);
    }
    
}

@end
