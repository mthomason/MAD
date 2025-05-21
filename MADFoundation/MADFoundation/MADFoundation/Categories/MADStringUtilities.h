//
//  MADStringUtilities.h
//  MADFoundation
//
//  Created by Michael on 6/3/17.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#ifndef MADStringUtilities_h
#define MADStringUtilities_h

#import <Foundation/NSString.h>

@interface MADStringUtilities : NSObject

+ (NSString *)stringByAppendingPeriod:(NSString *)string;
+ (NSString *)stringByAppendingKeyPath:(NSString *)keyPath toString:(NSString *)string;

@end

#endif
