//
//  MTReportFormatterPageDefinition.h
//  MAD
//
//  Created by Michael Thomason on 7/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTReportFormatterPageDefinition_h
#define MAD_MTReportFormatterPageDefinition_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>
#import <UIKit/UIGeometry.h>

@interface MTReportFormatterPageDefinition : NSObject

@property (nonatomic, assign) CGSize layoutSize;
@property (nonatomic, assign) UIEdgeInsets margins;

@end

#endif
