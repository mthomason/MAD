//
//  MADStandard.h
//  MADExplorer
//
//  Created by Michael Thomason on 6/20/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MADStandard : NSObject

+ (NSString *)newStringForDouble:(double)d;
+ (NSString *)newStringForUnsignedLong:(unsigned long)ul;
+ (NSString *)newStringForFileSize:(unsigned long long)filesize;

@end
