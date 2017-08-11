//
//  MADOperationConditionPolarQuestionAffirmative.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationConditionPolarQuestionNegative.h"
#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import "MADPromptOperationPolarQuestion.h"
#import "MADOperationConditionPolarQuestionAffirmativeResult.h"
#import "MADOperationConditionResult.h"
#import "NSError+MADOperationErrors.h"
#import <MAD/MADErrorUserInfo.h>

#import <os/log.h>

@interface MADOperationConditionPolarQuestionNegative ()

    @property (nonatomic, readwrite) NSUInteger tag;

@end

@implementation MADOperationConditionPolarQuestionNegative

- (void)dealloc {
    //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
}

- (instancetype)initWithTag:(NSUInteger)tag {
    if (self = [super init]) {
        _tag = tag;
    }
    return self;
}

#pragma mark - Condition

- (NSString *)name { return NSStringFromClass(self.class); }

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
    
    if (dependencies.count == 0) {
        MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:@"Not Satisified"
                                                                       andMessage:@"Not satisified."];
        NSError *error = [errorUserInfo errorWithDomain:self.name code:MADConditionFailed];
        result = [MADOperationConditionResult newOperationConditionResultFailed:error];
        return result;
    }

    for (NSOperation *dependency in dependencies) {
        if ([dependency conformsToProtocol:@protocol(MADOperationConditionPolarQuestionResultProtocol)] &&
            dependency.hash == self.tag) {
            if ( ! ((NSObject <MADOperationConditionPolarQuestionResultProtocol> *)dependency).result) {
                
                result = [MADOperationConditionPolarQuestionNegativeResult newOperationConditionResultSatisfied];
                ((MADOperationConditionPolarQuestionNegativeResult *)result).result = YES;
            } else {
                MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:@"Not Satisified"
                                                                               andMessage:@"Not satisified."];
                NSError *error = [errorUserInfo errorWithDomain:self.name code:MADConditionFailed];
                result = [MADOperationConditionResult newOperationConditionResultFailed:error];
            }
            break;
        }
    }
    if (result != nil) {
        return result;
    } else {
        MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:@"Not Satisified"
                                                                       andMessage:@"Not satisified."];
        NSError *error = [errorUserInfo errorWithDomain:self.name code:MADConditionFailed];
        result = [MADOperationConditionResult newOperationConditionResultFailed:error];
        return  result;
    }
    
}

@end
