//
//  NSThread+Extras.m
//  MAD
//
//  Created by Michael Thomason on 5/27/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "NSThread+Extras.h"

@implementation NSThread (Extras)

+ (void)completeOnMainThread:(void(^)(BOOL success, id obj))completion withObject:(id)obj andSuccess:(BOOL)success {
    if ([NSThread isMainThread]) {
        completion(success, obj);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(success, obj);
        });
    }
}

@end
