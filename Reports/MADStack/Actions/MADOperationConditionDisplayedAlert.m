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
#import "MADOperationConditionResult.h"
#import "NSError+MADOperationErrors.h"
#import <MAD/MADErrorUserInfo.h>

@interface MADOperationConditionDisplayedAlert ()

    @property (nonatomic, assign, readwrite) NSUInteger tag;

@end

@implementation MADOperationConditionDisplayedAlert

- (void)dealloc {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
}

- (instancetype)initWithTag:(NSUInteger)tag {
    if (self = [super init]) {
        _tag = tag;
        _reverseCondition = false;
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

    NSArray<__kindof NSOperation *> *dependencies = operation.dependencies;
    if (dependencies.count == 0) {
        MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:@"Not Satisified" andMessage:@"Not satisified."];
        NSError *error = [errorUserInfo errorWithDomain:self.name code:MADConditionFailed];
        MADOperationConditionResult *result = [MADOperationConditionResult newOperationConditionResultFailed:error];
        completion(result);
        return;
    }

    MADOperationConditionResult *result = nil;
    for (NSOperation *dependency in dependencies) {
        
        if ([dependency conformsToProtocol:@protocol(MADOperationConditionDisplayedAlertProtocol)] && dependency.hash == self.tag) {
            
            bool condition = [((NSObject <MADOperationConditionDisplayedAlertProtocol> *)dependency) alertDisplayed];
            
            if (self.reverseCondition) {
                condition = !condition;
            }
            
            if (condition) {
                result = [MADOperationConditionResult newOperationConditionResultSatisfied];
            } else {
                MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:@"Not Satisified" andMessage:@"Not satisified."];
                NSError *error = [errorUserInfo errorWithDomain:self.name code:MADConditionFailed];
                result = [MADOperationConditionResult newOperationConditionResultFailed:error];
            }
            
            break;
        }
    }
    
    if (result != nil) {
        completion(result);
    } else {
        MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:@"Not Satisified" andMessage:@"Not satisified."];
        NSError *error = [errorUserInfo errorWithDomain:self.name code:MADConditionFailed];
        MADOperationConditionResult *cresult = [MADOperationConditionResult newOperationConditionResultFailed:error];
        completion(cresult);
    }
}

@end
