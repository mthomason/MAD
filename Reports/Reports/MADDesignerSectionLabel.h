//
//  DesignerSectionLabel.h
//  Reports
//
//  Created by Michael Thomason on 7/24/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_DesignerSectionLabel_h
#define Reports_DesignerSectionLabel_h

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <MADCocoaExtensions/MADCocoaExtensions.h>

extern const CGFloat MADesignerSectionLabelFontSize;

@protocol MADDesignerSectionLabelDelegate;

@class RptqDocumentSection;

@interface MADDesignerSectionLabel : UILabel

@property (nonatomic, assign, readonly) BOOL selected;
@property (nonatomic, assign) BOOL indicatorFormFeed;
@property (nonatomic, assign) BOOL indicatorVisible;
@property (nonatomic, assign) CGFloat scale;

- (instancetype)initWithSection:(RptqDocumentSection *)section;
- (void)dimView;
- (void)normalView;

@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

@end

#endif
