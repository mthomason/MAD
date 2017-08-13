//
//  MADOperationConditionPolarQuestionAffirmative.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationConditionPolarQuestionAffirmative.h"
#import <asl.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import "MADPromptOperationPolarQuestion.h"
#import "MADOperationConditionPolarQuestionAffirmativeResult.h"
#import "MADOperationConditionResult.h"
#import "NSError+MADOperationErrors.h"
#import <MAD/MADErrorUserInfo.h>

#import <os/log.h>

@interface MADOperationConditionPolarQuestionAffirmative ()

    @property (nonatomic, readwrite) NSUInteger tag;

@end

@implementation MADOperationConditionPolarQuestionAffirmative

- (void)dealloc {
    //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
}

- (instancetype)initWithOperationIdentifier:(NSUInteger)tag {
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

    MADOperationConditionResult *result = nil;
    NSArray<__kindof NSOperation *> *dependencies = operation.dependencies;
    if (dependencies.count == 0) {
        MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:@"Not Satisified"
                                                                       andMessage:@"Not satisified."];
        NSError *error = [errorUserInfo errorWithDomain:self.name code:MADConditionFailed];
        result = [MADOperationConditionResult newOperationConditionResultFailed:error];
        asl_log(NULL, NULL, ASL_LEVEL_DEBUG, "Result evaluated to NO.");
        return result;
    }
    
    for (MADOperation *dependency in dependencies) {
        if ([dependency conformsToProtocol:@protocol(MADOperationConditionPolarQuestionResultProtocol)] &&
            dependency.identifier == self.tag) {
            
            if (((NSObject <MADOperationConditionPolarQuestionResultProtocol> *)dependency).result) {

                result = [MADOperationConditionResult newOperationConditionResultSatisfied];
                
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
        asl_log(NULL, NULL, ASL_LEVEL_DEBUG, "Result evaluated to %s.", result.isSucceed ? "YES" : "NO");
        return result;
    } else {
        MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:@"Not Satisified"
                                                                       andMessage:@"Not satisified."];
        NSError *error = [errorUserInfo errorWithDomain:self.name code:MADConditionFailed];
        result = [MADOperationConditionResult newOperationConditionResultFailed:error];
        asl_log(NULL, NULL, ASL_LEVEL_DEBUG, "Result evaluated to NO.");
        return result;
    }

}

@end
