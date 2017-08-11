//
//  NSString+Common.h
//  MADFoundation
//
//  Created by Michael on 6/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Foundation_NSString_Common_h
#define MAD_Foundation_NSString_Common_h

#import <Foundation/NSString.h>

@interface NSString (Common)

- (NSString *)stringByAppendingPeriod;
- (NSString *)stringByAppendingKeyPath:(NSString *)keyPath;

@end

#endif
