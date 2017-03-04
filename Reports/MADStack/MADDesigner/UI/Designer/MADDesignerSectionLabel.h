//
//  DesignerSectionLabel.h
//  Reports
//
//  Created by Michael Thomason on 7/24/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_DesignerSectionLabel_h
#define Reports_DesignerSectionLabel_h

#import <UIKit/UILabel.h>

extern const CGFloat MADesignerSectionLabelFontSize;

@protocol MADDesignerSectionLabelDelegate;

@class MADReportSection, UITapGestureRecognizer;

@interface MADDesignerSectionLabel : UILabel

    @property (nonatomic, assign, readonly) BOOL selected;
    @property (nonatomic, assign) BOOL indicatorFormFeed;
    @property (nonatomic, assign) BOOL indicatorVisible;
    @property (nonatomic, assign) CGFloat scale;

    - (instancetype)initWithSection:(MADReportSection *)section;
    - (void)dimView;
    - (void)normalView;

    @property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

@end

#endif
