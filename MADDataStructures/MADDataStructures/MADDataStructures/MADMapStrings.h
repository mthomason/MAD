//
//  MADMapStrings.h
//  MADDataStructures
//
//  Created by Michael on 1/1/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_DataStructures_MADMapStrings_h
#define MAD_DataStructures_MADMapStrings_h

#import <Foundation/NSObject.h>

@class NSString;

typedef NS_ENUM(short, MADMapDataType) {
    MADMapDataTypeShort,
    MADMapDataTypeInteger,
    MADMapDataTypeUnsignedInteger,
};

@protocol MADMapStringsProtocol <NSObject>
	- (instancetype)initWithType:(MADMapDataType)t;
	- (unsigned long)count;
@end

@interface MADMapStrings : NSObject
	<MADMapStringsProtocol>
@end

@interface MADMapStringsUnsignedInteger : MADMapStrings
	- (void)setObject:(NSString *)str toKey:(NSUInteger)key;
	- (NSString *)objectAtIndex:(NSUInteger)i;
@end

@interface MADMapStringsInteger : MADMapStrings
	- (void)setObject:(NSString *)str toKey:(NSInteger)key;
	- (NSString *)objectAtIndex:(NSInteger)i;
@end

@interface MADMapStringsShort : MADMapStrings
	- (void)setObject:(NSString *)str toKey:(short)key;
	- (NSString *)objectAtIndex:(short)i;
@end

#endif
