//
//  MADResult.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/26/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Scrimpter_MADValue_h
#define MAD_Scrimpter_MADValue_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SCVarableType) {
    SCVarableTypeDouble,
    SCVarableTypeString,
    SCVarableTypeBoolean,
    SCVarableTypeNull
};

@interface MADValue : NSObject

@property (nonatomic, assign, readonly) SCVarableType type;
@property (nonatomic, retain, readonly) id value;

+ (id)value:(id)value withType:(SCVarableType)type;
+ (id)nullValue;
- (double)doubleValue;
- (NSString *)stringValue;

@end

#endif
