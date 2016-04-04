//
//  MADOperationConditionHasCredientals.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationConditionMissingResultString.h"
#import <Foundation/NSOperation.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import "MADOperationConditionHasResultStringResult.h"
#import "MADOperation.h"
#import "NSError+MADOperationErrors.h"
#import "MADKeyChainOperationGet.h"
#import "MADOperationConditionResult.h"
#import <MAD/MADErrorUserInfo.h>

@interface MADOperationConditionMissingResultString ()

    @property (nonatomic, readwrite, copy) NSString *key;

@end

@implementation MADOperationConditionMissingResultString

- (void)dealloc {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
}

- (instancetype)initWithKey:(NSString *)key {
    if (self = [super init]) {
        self.key = key;
    }
    return self;
}

#pragma mark - Condition

- (NSString *)name { return NSStringFromClass(self.class); }

- (BOOL)isMutuallyExclusive { return NO; }

- (NSOperation *)dependencyForOperation:(MADOperation *)operation { return nil; }

- (void)evaluateForOperation:(MADOperation *)operation
                  completion:(void (^)(MADOperationConditionResult *))completion {

    NSArray <__kindof NSOperation *> *dependencies = operation.dependencies;
    if (dependencies.count == 0) {
        MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:@"Not Satisified" andMessage:@"Not satisified."];
        NSError *error = [errorUserInfo errorWithDomain:self.name code:MADConditionFailed];
        MADOperationConditionResult *result = [MADOperationConditionResult newOperationConditionResultFailed:error];
        completion(result);
        return;
    }
    
    MADOperationConditionResult *result = nil;
    for (NSOperation *dependency in dependencies) {
        if ([dependency conformsToProtocol:@protocol(MADOperationResultStringProtocol)] &&
            [self.key isEqualToString: ((NSObject <MADOperationResultStringProtocol> *) dependency).key]) {
            
            if(!((NSObject <MADOperationResultStringProtocol> *) dependency).success) {
                
                result = [MADOperationConditionHasResultStringResult newOperationConditionResultSatisfied];
                ((MADOperationConditionHasResultStringResult *)result).result = ((NSObject <MADOperationResultStringProtocol> *) dependency).value;
                
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
        result = [MADOperationConditionResult newOperationConditionResultFailed:error];
        completion(result);
    }
    
}

@end
