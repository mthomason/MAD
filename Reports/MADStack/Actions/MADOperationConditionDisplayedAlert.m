//
//  MADOperationConditionDisplayedAlert.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/20/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationConditionDisplayedAlert.h"
#import "MADOperationConditionResult.h"
#import "MADOperation.h"
#import <Foundation/NSArray.h>

@interface MADOperationConditionDisplayedAlert ()

@property (nonatomic, readwrite) NSUInteger tag;

@end

@implementation MADOperationConditionDisplayedAlert

- (instancetype)initWithTag:(NSUInteger)tag {
    if (self = [super init]) {
        _tag = tag;
        _reverseCondition = false;
    }
    return self;
}

#pragma mark - Condition

- (NSString *)name { return NSStringFromClass(self.class); }

- (BOOL)isMutuallyExclusive { return NO; }

- (NSOperation *)dependencyForOperation:(MADOperation *)operation { return nil; }

- (void)evaluateForOperation:(MADOperation *)operation
                  completion:(void (^)(MADOperationConditionResult *))completion {
    
    NSArray<__kindof NSOperation *> *dependencies = operation.dependencies;
    if (dependencies.count == 0) {
        
        completion([MADOperationConditionResult failed:nil]);
        
    }

    MADOperationConditionResult *result = nil;
    

    for (NSOperation *dependency in dependencies) {
        
        if ([dependency conformsToProtocol:@protocol(MADOperationConditionDisplayedAlertProtocol)] && dependency.hash == self.tag) {
            
            bool condition = [((NSObject <MADOperationConditionDisplayedAlertProtocol> *)dependency) alertDisplayed];
            
            if (self.reverseCondition) {
                condition = !condition;
            }
            
            if (condition) {
                result = [MADOperationConditionResult satisfied];
            } else {
                result = [MADOperationConditionResult failed:nil];
            }
            
            break;
        }
    }
    
    if (result != nil) {
        completion(result);
    } else {
        completion([MADOperationConditionResult failed:nil]);
    }

    
}

@end
