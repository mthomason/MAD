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

@class UITapGestureRecognizer, MADRulerView, MADDesignerSectionView, MADDesignerSectionLabel;

@protocol MADDesignerDesignViewDataSource, MADDesignerDesignViewDelegate;

@interface MADDesignerLayoutDesignView : UIView

    @property (nonatomic, weak) id <MADDesignerDesignViewDataSource> datasource;
    @property (nonatomic, weak) id <MADDesignerDesignViewDelegate> delegate;

    @property (nonatomic, strong) MADRulerView *ruler;

    @property (readonly, nonatomic, strong) NSLayoutConstraint *layoutConstraintDesignerContentViewHeight;

    @property (readonly, nonatomic, strong) UITapGestureRecognizer *strayTouchGestureRecognizer;
    @property (readonly, nonatomic, strong) NSSet <UITapGestureRecognizer *> *sectionLabelGestureRecognizers;
    @property (readonly, nonatomic, strong) NSSet <MADDesignerSectionView *> *passthroughContainers;

    @property (readonly, nonatomic, strong) NSArray <NSLayoutConstraint *> *layoutConstraintsSectionsVerticalBuffer;
    @property (readonly, nonatomic, strong) NSArray <NSLayoutConstraint *> *rulerHorizontalConstraints;
    @property (readonly, nonatomic, strong) NSArray <NSLayoutConstraint *> *rulerVerticalConstraints;
    @property (readonly, nonatomic, strong) NSArray <NSLayoutConstraint *> *layoutConstraintsSectionsSidesBorder;
    @property (readonly, nonatomic, strong) NSArray <NSLayoutConstraint *> *layoutConstraintSectionLabelHeightContainer;

    @property (readonly, nonatomic, strong) NSDictionary <NSNumber *, __kindof NSLayoutConstraint *> *layoutConstraintsReportSectionHeight;
    @property (readonly, nonatomic, strong) NSDictionary <NSNumber *, MADDesignerSectionView *> *sectionViewsDictionary;
    @property (readonly, nonatomic, strong) NSDictionary <NSNumber *, MADDesignerSectionLabel *> *sectionControlViewsDictionary;

    @property (readwrite, nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *viewDidAppearDesignerScrollViewConstraints;
    @property (readwrite, nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *viewDidAppearDesignerContentViewConstraints;

    - (void)reloadData;
    - (void)reloadDataIfNeeded;

    - (UITapGestureRecognizer *)strayTouchGestureRecognizer;

@end

#endif
