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
#import "Constants.h"

extern const CGFloat MADesignerSectionLabelFontSize;

@protocol DesignerSectionLabelDelegate;

@class RptqDocumentSection;

@interface DesignerSectionLabel : UILabel

@property (nonatomic, weak) id <DesignerSectionLabelDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL selected;
@property (nonatomic, assign) BOOL indicatorFormFeed;
@property (nonatomic, assign) BOOL indicatorVisible;
@property (nonatomic, assign) CGFloat scale;

- (instancetype)initWithSection:(RptqDocumentSection *)section NS_DESIGNATED_INITIALIZER;
- (void)dimView;
- (void)normalView;

@end

@protocol DesignerSectionLabelDelegate <NSObject>

- (void)toggleSectionControlPanel:(DesignerSectionLabel *)label;

@end

#endif
