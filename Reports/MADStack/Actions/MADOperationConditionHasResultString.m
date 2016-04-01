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
#import "MADOperationConditionResult.h"
#import <MAD/MADErrorUserInfo.h>

@interface MADOperationConditionHasResultString ()

    @property (nonatomic, readwrite, copy) NSString *key;

@end

@implementation MADOperationConditionHasResultString

- (void)dealloc {
    NSLog(@"Operation deallocated. %s", __PRETTY_FUNCTION__);
}

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

- (void)evaluateForOperation:(MADOperation *)operation completion:(void (^)(MADOperationConditionResult *))completion {

    NSArray<__kindof NSOperation *> *dependencies = operation.dependencies;
    
    if (dependencies.count == 0) {
        MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:@"Not Satisified" andMessage:@"Not satisified."];
        NSError *error = [NSError errorWithDomain:self.name code:MADConditionFailed userInfo:errorUserInfo.userinfo];
        completion([MADOperationConditionResult failed:error]);
        return;
    }
    
    MADOperationConditionResult *result = nil;
    
    for (NSOperation *dependency in dependencies) {
    
        if ([dependency conformsToProtocol:@protocol(MADOperationResultStringProtocol)] &&
            [self.key isEqualToString: ((NSObject <MADOperationResultStringProtocol> *) dependency).key]) {
            
            if (((NSObject <MADOperationResultStringProtocol> *) dependency).success) {
                
                result = [MADOperationConditionHasResultStringResult satisfied];
                
                ((MADOperationConditionHasResultStringResult *)result).result = ((NSObject <MADOperationResultStringProtocol> *) dependency).value;
                
            } else {
                MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:@"Not Satisified" andMessage:@"Not satisified."];
                NSError *error = [NSError errorWithDomain:self.name code:MADConditionFailed userInfo:errorUserInfo.userinfo];
                result = [MADOperationConditionResult failed:error];
            }
            break;
        }
    }
    
    if (result != nil) {
        completion(result);
    } else {
        MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:@"Not Satisified" andMessage:@"Not satisified."];
        NSError *error = [NSError errorWithDomain:self.name code:MADConditionFailed userInfo:errorUserInfo.userinfo];
        completion([MADOperationConditionResult failed:error]);
    }
    
}

@end
