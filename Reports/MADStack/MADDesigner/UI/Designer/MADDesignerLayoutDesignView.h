//
//  MADDesignerLayoutDesignView.h
//  MAD Designer
//
//  Created by Michael on 5/26/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDesignerLayoutDesignView_h
#define Reports_MADDesignerLayoutDesignView_h

#import <UIKit/UIView.h>

extern const CGFloat MTReportDesignerBorderPaddingDetail;
extern const CGFloat MTReportDesignerBorderPaddingVertical;
extern const CGFloat MTReportDesignerBorderPaddingSides;
extern const CGFloat MTReportDesignerBufferPaddingVertical;
extern const CGFloat MTReportDesignerSectionLabelPaddingRight;
extern const CGFloat MTReportDesignerSectionLabelHeight;

@class UITapGestureRecognizer, MADRulerView, MADDesignerSectionView, MADDesignerSectionLabel,
        MADDesignerElementView;

@protocol MADDesignerDesignViewDataSource, MADDesignerDesignViewDelegate;

@interface MADDesignerLayoutDesignView : UIView

    @property (nonatomic, weak) id <MADDesignerDesignViewDataSource> datasource;
    @property (nonatomic, weak) id <MADDesignerDesignViewDelegate> delegate;

    @property (readonly, nonatomic, strong) NSMutableDictionary <NSNumber *, MADDesignerSectionView *> *sectionViews;
    @property (readonly, nonatomic, strong) NSMutableDictionary <NSNumber *, MADDesignerSectionLabel *> *sectionLabels;

    @property (readonly, nonatomic, strong) NSMutableSet <NSNumber *> *selectedSections;

    @property (nonatomic, strong) MADRulerView *ruler;

    @property (readonly, nonatomic, strong) NSLayoutConstraint *layoutConstraintDesignerContentViewHeight;

    @property (readonly, nonatomic, strong) UITapGestureRecognizer *strayTouchGestureRecognizer;
    @property (readonly, nonatomic, strong) NSMutableSet <UITapGestureRecognizer *> *sectionLabelGestureRecognizers;
    @property (readonly, nonatomic, strong) NSMutableSet <MADDesignerSectionView *> *passthroughContainers;

    @property (readonly, nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *layoutConstraintsSectionsVerticalBuffer;
    @property (readonly, nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *layoutConstraintsSectionsSidesBorder;
    @property (readonly, nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *layoutConstraintSectionLabelHeightContainer;

    - (void)setNeedsCleanup;
    - (void)cleanup;

    - (void)setNeedsReload;
    - (void)reloadData;
    - (void)reloadDataIfNeeded;

    - (UITapGestureRecognizer *)strayTouchGestureRecognizer;
    - (void)repositionSectionViews:(CGRect)presentedRect;
    - (CGRect)popoverRectForSelectedViews:(NSSet <UIView *> *)views;

    - (CGFloat)sizeHeight;

    - (void)removeBorderFromSections;
    - (void)removeBorderFromAllSectionViews;
    - (BOOL)removeBorderFromSectionLabel:(MADDesignerSectionLabel *)label;
    - (void)applyBorderToSectionLabel:(MADDesignerSectionLabel *)view;
    - (BOOL)removeBorderFromView:(MADDesignerElementView *)view;
    - (void)applyBorderToView:(MADDesignerElementView *)view;

    - (void)updateSection:(NSNumber *)sectionID height:(CGFloat)height;

@end

#endif
