//
//  NSError+Constructors.m
//  MAD
//
//  Created by Michael Thomason on 4/1/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "NSError+Constructors.h"

@implementation NSError (Constructors)

+ (instancetype)errorWithDomain:(NSString *)domain code:(NSInteger)code title:(NSString *)title andMessage:(NSString *)message {
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : message,
                                NSLocalizedFailureReasonErrorKey : title};
    return [NSError errorWithDomain:domain code:code userInfo:userInfo];
}

@end
