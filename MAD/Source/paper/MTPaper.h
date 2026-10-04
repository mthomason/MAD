//
//  MTPaper.h
//  Reports
//
//  Created by Michael Thomason on 5/28/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTPaper_h
#define Reports_MTPaper_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>

#import <MAD/MADPaperType.h>

@interface MTPaper : NSObject

	- (instancetype)initWithType:(MTPaperType)papertype NS_DESIGNATED_INITIALIZER;

	@property (nonatomic, assign, readonly) MTPaperType paperType;
	@property (nonatomic, assign, readonly) CGSize paperSize;
	@property (nonatomic, assign, readonly) CGRect bounds;

	+ (CGSize)sizeForType:(MTPaperType)papertype;

@end

#endif
