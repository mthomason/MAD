//
//  NSError+MADOperationErrors.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "NSError+MADOperationErrors.h"


@implementation NSError (MADOperationErrors)

+ (instancetype)errorWithCode:(NSInteger)code {
    return [self errorWithCode:code userInfo:nil];
}

+ (instancetype)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)info {
    return [NSError errorWithDomain:@"OperationErrors" code:code userInfo:info];
}

@end
