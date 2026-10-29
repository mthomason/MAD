//
//  MADReportFormatterPageDefinition.h
//  MAD
//
//  Created by Michael Thomason on 7/20/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADReportFormatterPageDefinition_h
#define MAD_MADReportFormatterPageDefinition_h

#include <TargetConditionals.h>
#import <Foundation/NSObject.h>
#if defined(__APPLE__) && TARGET_OS_OSX
#import <MADCocoaExtensions/CGGeometry+Extras.h>
#else
#import <UIKit/UIGeometry.h>
#endif
#import <CoreGraphics/CGBase.h>

@interface MADPageOptions : NSObject

	@property (nonatomic, assign) CGSize layoutSize;
	@property (nonatomic, assign) UIEdgeInsets margins;

@end

#endif
