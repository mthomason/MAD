//
//  MTReportDesigner.h
//  MAD
//
//  Created by Michael Thomason on 3/16/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesigner_h
#define Reports_MTReportDesigner_h

#import <Foundation/Foundation.h>

@interface MTReportDesigner : NSObject

@property (nonatomic, assign) CGFloat zoomScaleRestore;
@property (nonatomic, assign) CGRect boundsOnDisappear;
@property (nonatomic, assign) BOOL shownAndHidden;
@property (nonatomic, assign) BOOL toolboxIsVisible;
@property (nonatomic, assign) CGPoint contentOffsetOnShowToolbox;

@end

#endif
