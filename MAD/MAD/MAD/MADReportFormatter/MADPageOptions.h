//
//  MADReportFormatterPageDefinition.h
//  MAD
//
//  Created by Michael Thomason on 7/20/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADReportFormatterPageDefinition_h
#define MAD_MADReportFormatterPageDefinition_h

#import <Foundation/NSObject.h>
#import <UIKit/UIGeometry.h>
#import <CoreGraphics/CGBase.h>

@interface MADPageOptions : NSObject

	@property (nonatomic, assign) CGSize layoutSize;
	@property (nonatomic, assign) UIEdgeInsets margins;

@end

#endif
