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
    
    
    if ([operation conformsToProtocol:@protocol(MADOperationConditionDisplayedAlertProtocol)]) {
        
        bool condition = [((NSObject <MADOperationConditionDisplayedAlertProtocol> *)operation) alertDisplayed] && operation.hash == self.tag;

        if (self.reverseCondition) {
            condition = !condition;
        }
        
        if (condition) {
            
            MADOperationConditionResult *result = [MADOperationConditionResult satisfied];
            completion(result);
            
        } else {
            
            MADOperationConditionResult *result = [MADOperationConditionResult failed:nil];
            completion(result);
            
        }
    } else {
        completion([MADOperationConditionResult failed:nil]);
    }
}

@end
