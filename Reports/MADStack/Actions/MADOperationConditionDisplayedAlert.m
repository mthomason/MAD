//
//  MADOperationConditionDisplayedAlert.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/20/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationConditionDisplayedAlert.h"

#import "MADOperationConditionResult.h"
#import "MADOperation.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>

#import "MADOperationConditionResult.h"
#import "NSError+MADOperationErrors.h"

#import <MAD/MADErrorUserInfo.h>

@interface MADOperationConditionDisplayedAlert ()

    @property (nonatomic, assign, readwrite) NSUInteger tag;

@end

@implementation MADOperationConditionDisplayedAlert

- (void)dealloc {
    //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
}

- (instancetype)initWithTag:(NSUInteger)tag {
    if (self = [super init]) {
        _tag = tag;
        _reverseCondition = NO;
    }
    return self;
}

#pragma mark - Condition

- (NSString *)name {
    NSString *name = NSStringFromClass(self.class);
    return name;
}

- (BOOL)isMutuallyExclusive { return NO; }

- (NSOperation *)dependencyForOperation:(MADOperation *)operation { return nil; }

- (void)evaluateForOperation:(MADOperation *)operation completion:(void (^)(MADOperationConditionResult *))completion {
    MADOperationConditionResult *result;
    result = [self evaluateForOperation:operation];
    completion(result);
}

- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation {

    NSArray<__kindof NSOperation *> *dependencies = operation.dependencies;
    MADOperationConditionResult *result = nil;
    NSString *domain = self.name.copy;
    if (dependencies.count == 0) {
        MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle: @"Not Satisified"
                                                                       andMessage: @"Not satisified."];
        NSError *error = [errorUserInfo errorWithDomain: domain
                                                   code: MADConditionFailed];
        result = [MADOperationConditionResult newOperationConditionResultFailed:error];
        return result;
    }

    for (NSOperation *dependency in dependencies) {
        
        if ([dependency conformsToProtocol:@protocol(MADOperationConditionDisplayedAlertProtocol)] &&
            dependency.hash == self.tag) {
            
            BOOL condition = [((NSObject <MADOperationConditionDisplayedAlertProtocol> *)dependency) alertDisplayed];
            
            if (self.reverseCondition) { condition = !condition; }
            
            if (condition) {
                
                result = [MADOperationConditionResult newOperationConditionResultSatisfied];
                
            } else {
            
                MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle: @"Not Satisified"
                                                                               andMessage: @"Not satisified."];
                NSError *error = [errorUserInfo errorWithDomain: domain
                                                           code: MADConditionFailed];
                result = [MADOperationConditionResult newOperationConditionResultFailed:error];
            
            }
            
            break;
        }
    }
    
    if (result != nil) {
        
        return result;
    
    } else {
        
        MADErrorUserInfo *errorUserInfo;
        NSError *error;
        
        errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle: @"Not Satisified"
                                                     andMessage: @"Not satisified."];
        error = [errorUserInfo errorWithDomain: domain
                                          code: MADConditionFailed];
        
        result = [MADOperationConditionResult newOperationConditionResultFailed:error];
        return result;
    
    }
}

@end
