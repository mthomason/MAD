//
//  NSThread+Extras.h
//  MAD
//
//  Created by Michael Thomason on 5/27/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_NSThread_Extras_h
#define Reports_NSThread_Extras_h

#import <Foundation/Foundation.h>

@interface NSThread (Extras)

+ (void)completeOnMainThread:(void(^)(BOOL success, id obj))completion withObject:(id)obj andSuccess:(BOOL)success;

@end

#endif
