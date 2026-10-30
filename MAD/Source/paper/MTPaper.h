//
//  MTPaper.h
//  Reports
//
//  Created by Michael Thomason on 5/28/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTPaper_h
#define Reports_MTPaper_h

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>
#import <CoreGraphics/CGGeometry.h>

#import <MAD/MADPaperType.h>

NS_ASSUME_NONNULL_BEGIN

@interface MTPaper : NSObject

	- (instancetype)initWithType:(MTPaperType)papertype NS_DESIGNATED_INITIALIZER;

	@property (nonatomic, assign, readonly) MTPaperType paperType;
	@property (nonatomic, assign, readonly) CGSize paperSize;
	@property (nonatomic, assign, readonly) CGRect bounds;
	@property (nonatomic, copy, readonly) NSString *displayName;
	@property (nonatomic, copy, readonly) NSString *shortDisplayName;

	+ (CGSize)sizeForType:(MTPaperType)papertype;
	+ (NSArray<NSNumber *> *)standardPaperTypes;
	+ (NSString *)displayNameForPaperType:(MTPaperType)papertype;
	+ (NSString *)shortDisplayNameForPaperType:(MTPaperType)papertype;

@end

NS_ASSUME_NONNULL_END

#endif
