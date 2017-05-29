//
//  MADDesignerLayoutDesignView.m
//  MAD Designer
//
//  Created by Michael on 5/26/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerLayoutDesignView.h"
#import "MADRulerView.h"
#import "NSLayoutConstraint+Designer.h"

#import "MADDesignerSectionView.h"
#import "MADDesignerSectionLabel.h"

#import "MADReportSectionDataSourceProtocol.h"
#import "MADReportSectionDelegateProtocol.h"

#import "MADDesignerSectionLayoutLiquid.h"

#import "UITapGestureRecognizer+Designer.h"

const CGFloat MTReportDesignerBorderPaddingDetail        =  3.0000f;
const CGFloat MTReportDesignerBorderPaddingVertical      =  3.0000f;
const CGFloat MTReportDesignerBorderPaddingSides         =  8.0000f;
const CGFloat MTReportDesignerBufferPaddingVertical      =  2.0000f;
const CGFloat MTReportDesignerSectionLabelPaddingRight   =  8.0000f;
const CGFloat MTReportDesignerSectionLabelHeight         = 20.0000f;

@interface MADDesignerLayoutDesignView ()
    <UIGestureRecognizerDelegate>

    @property (readwrite, nonatomic, strong) NSLayoutConstraint *layoutConstraintDesignerContentViewHeight;
    @property (readwrite, nonatomic, strong) NSArray <NSLayoutConstraint *> *rulerHorizontalConstraints;
    @property (readwrite, nonatomic, strong) NSArray <NSLayoutConstraint *> *rulerVerticalConstraints;

    @property (readwrite, nonatomic, strong) NSMutableSet <MADDesignerSectionView *> *passthroughContainers;
    @property (readwrite, nonatomic, strong) NSMutableSet <UITapGestureRecognizer *> *sectionLabelGestureRecognizers;

    @property (readwrite, nonatomic, strong) UITapGestureRecognizer *strayTouchGestureRecognizer;
    @property (readwrite, nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *layoutConstraintsSectionsVerticalBuffer;
    @property (readwrite, nonatomic, strong) NSMutableDictionary <NSNumber *, __kindof NSLayoutConstraint *> *layoutConstraintsReportSectionHeight;
    @property (readwrite, nonatomic, strong) NSMutableDictionary <NSNumber *, MADDesignerSectionView *> *sectionViewsDictionary;
    @property (readwrite, nonatomic, strong) NSMutableDictionary <NSNumber *, MADDesignerSectionLabel *> *sectionControlViewsDictionary;
    @property (readwrite, nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *layoutConstraintsSectionsSidesBorder;
    @property (readwrite, nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *layoutConstraintSectionLabelHeightContainer;

/*    - (instancetype)initWithCoder:(NSCoder *)aDecoder;
    - (instancetype)initWithFrame:(CGRect)frame;
    - (void)setup;
    - (void)updateConstraints;
    - (void)removeFromSuperview;
    - (void)willMoveToSuperview:(UIView *)newSuperview;*/

@end

@implementation MADDesignerLayoutDesignView {
    BOOL _needsReload;
    struct {
        BOOL handleTapLabel;
        BOOL handleTapStray;
    } _delegateHas;
    struct {
        BOOL numberOfSectionsInDesignView;
    } _dataSourceHas;
}

- (void)dealloc {
    _datasource = nil;
    _rulerVerticalConstraints = nil;
    _rulerVerticalConstraints = nil;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setDatasource:(NSObject<MADDesignerDesignViewDataSource> *)datasource {
    _dataSourceHas.numberOfSectionsInDesignView = [datasource respondsToSelector:@selector(numberOfSectionsInDesignView:)];
    _datasource = datasource;
}

- (void)setDelegate:(id <MADDesignerDesignViewDelegate>)delegate {
    _delegateHas.handleTapLabel = [delegate respondsToSelector:@selector(designView:handleTapLabel:)];
    _delegateHas.handleTapStray = [delegate respondsToSelector:@selector(designView:handleTapStray:)];
    _delegate = delegate;
}

- (void)setup {
    MADRulerView *ruler = [[MADRulerView alloc] initWithFrame:CGRectZero];
    
    NSArray <NSLayoutConstraint *> *rulerVerticalConstraints, *rulerHorizontalConstraints;
    rulerVerticalConstraints = [MADLayoutConstraint constraintForRuler: ruler
                                                              designer: self
                                                             marginTop: MTReportDesignerBorderPaddingVertical
                                                                 heigh: MTReportDesignerRulerHeight
                                                           scaleFactor: 1.0];
    
    rulerHorizontalConstraints = [MADLayoutConstraint constraintForRuler: ruler
                                                                designer: self
                                                              sideMargin: MTReportDesignerBorderPaddingSides
                                                             scaleFactor: 1.0];
    
    NSArray <NSLayoutConstraint *> *allConstraints = [rulerVerticalConstraints arrayByAddingObjectsFromArray:rulerHorizontalConstraints];
    
    [self addSubview:ruler];
    [self addConstraints:allConstraints];
    
    self.rulerVerticalConstraints = rulerVerticalConstraints;
    self.rulerHorizontalConstraints = rulerHorizontalConstraints;
    
    self.ruler = ruler;
    
    allConstraints = nil;
}

- (void)updateConstraints {
    if (self.rulerVerticalConstraints == nil) {
    }
    [super updateConstraints];
}

/*- (void)removeFromSuperview {
    [super removeFromSuperview];
    [self removeConstraints:self.rulerConstraints];
    self.rulerConstraints = nil;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (newSuperview == nil) {
        [self removeConstraints:self.rulerConstraints];
        self.rulerConstraints = nil;
    }
}*/

- (UITapGestureRecognizer *)strayTouchGestureRecognizer {
    if (_strayTouchGestureRecognizer == nil) {
        UITapGestureRecognizer *tap;
        tap = [MADTapGestureRecognizer newTapGestureRecognizerStrayTouchWithTarget: self
                                                                            action: @selector(handleTapStray:)
                                                                          delegate: self];
        //[tap requireGestureRecognizerToFail:tapGestureDoubleTap];
        [self addGestureRecognizer:tap];
        _strayTouchGestureRecognizer = tap;
    }
    return _strayTouchGestureRecognizer;
}

- (void)setNeedsUpdateConstraints {
    [super setNeedsUpdateConstraints];
    [self.ruler setNeedsUpdateConstraints];
}

- (void)setNeedsLayout {
    [super setNeedsLayout];
    [self.ruler setNeedsLayout];
}

- (void)setNeedsDisplay {
    [super setNeedsDisplay];
    [self.ruler setNeedsDisplay];
}

- (void)setNeedsReload {
    _needsReload = YES;
}

// Called to update the view.

- (void)reloadData {
    
    if (_datasource == nil) return;
    
    //RptqDocument *document = [maDocument activeDocumentModel];
    
    //MADReportSectionsEnumerator *reportSectionsEnumerator;
    //reportSectionsEnumerator = [[MADReportSectionsEnumerator alloc] initWithDocument:document];
    
    id <MADDesignerDesignViewDataSource> datasource = _datasource;

    NSUInteger numberOfSections = _dataSourceHas.numberOfSectionsInDesignView ?
                            [datasource numberOfSectionsInDesignView:self] : 0;
    
    
    NSMutableArray <NSNumber *> *reportSectionKeyTracker;
    NSMutableArray <NSLayoutConstraint *> *scrollerLayoutConstraints,
    *viewDidAppearDesignerContentViewConstraints,
    *constraintsSectionsSidesBorder,
    *constraintSectionLabelHeightContainer,
    *constraintsSectionsVerticalBuffer;
    
    NSMutableDictionary <NSNumber *, NSLayoutConstraint *> *constraintsReportSectionHeight;
    
    reportSectionKeyTracker = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
    
    scrollerLayoutConstraints = [[NSMutableArray alloc] initWithCapacity:numberOfSections * 2 + 6];
    viewDidAppearDesignerContentViewConstraints = [[NSMutableArray alloc] initWithCapacity:numberOfSections * 5];
    constraintsSectionsSidesBorder = [[NSMutableArray alloc] initWithCapacity:numberOfSections * 2 + 2];
    constraintSectionLabelHeightContainer = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
    constraintsSectionsVerticalBuffer = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
    constraintsReportSectionHeight = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];
    
    NSMutableDictionary <NSNumber *, MADDesignerSectionView *> *sectionViewsDictionary;
    NSMutableDictionary <NSNumber *, MADDesignerSectionLabel *> *sectionControlViewsDictionary;
    
    sectionViewsDictionary          = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];
    sectionControlViewsDictionary   = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];
    
    NSMutableSet <MADDesignerSectionView *> *passthroughContainers;
    passthroughContainers = [[NSMutableSet alloc] initWithCapacity:numberOfSections];
    
    [scrollerLayoutConstraints addObjectsFromArray:self.rulerHorizontalConstraints];
    [scrollerLayoutConstraints addObjectsFromArray:self.rulerVerticalConstraints];
    
    [constraintsSectionsSidesBorder addObjectsFromArray:self.rulerHorizontalConstraints];
    
    CGFloat sectionHeights = CGSizeZero.height + MTReportDesignerRulerHeight + MTReportDesignerBorderPaddingVertical;
    
    NSLayoutConstraint *constraintViewTop,
    *constraintViewHeight,
    *constraintLabelRight,
    *constraintLabelBottom,
    *constraintLabelHeight,
    *constraintViewLeft,
    *constraintViewRight;
    NSArray *collectionViewConstraints, *sectionViewLabelConstraints;
    //UIGestureRecognizer *strayTouchGesture = self.strayTouchGesture;
    
    NSMutableSet <UITapGestureRecognizer *> *sectionLabelGestureRecognizers = [[NSMutableSet alloc] init];
    NSNumber *reportSectionKey;
    MADDesignerSectionView *sectionView;
    MADDesignerSectionLabel *sectionViewLabel;
    UITapGestureRecognizer *tapGestureRecognizer;
    NSString *localizedDisplayName;
    
    CGFloat sectionHeight;
    for (NSUInteger sectionIndex = 0; sectionIndex < numberOfSections; sectionIndex++) {
//    for (MADReportSection *reportSection in reportSectionsEnumerator) {
        
//        reportSectionKey = @(reportSection.identifier);
        
        //sectionHeights += (MTReportDesignerBufferPaddingVertical + reportSection.height);
//        sectionView = [datasource designView:self
//                sectionViewForSectionAtIndex:sectionIndex];
//        sectionView = [MADDesignerSectionView newDesignerSectionView: reportSection.identifier
//                                                           isVisible: reportSection.isVisible
//                                                            delegate: self];
        sectionView = [datasource designView:self sectionViewForSectionAtIndex:sectionIndex];
        sectionHeight = [datasource designView:self heightForSectionAtIndex:sectionIndex];
        sectionHeights += MTReportDesignerBufferPaddingVertical + sectionHeight;
        
        localizedDisplayName = [datasource designView:self titleForSectionAtIndex:sectionIndex];
        reportSectionKey = @([datasource designView:self identifierAtIndex:sectionIndex]);
        ((MADDesignerSectionLayoutLiquid *)sectionView.collectionViewLayout).designViewIdentifier = (NSInteger)sectionIndex;
        //((MADDesignerSectionLayoutLiquid *)sectionView.collectionViewLayout).designViewIdentifier = sectionCounter;
        //localizedDisplayName = [reportSection localizedDisplayName];
        //sectionViewLabel = [[MADDesignerSectionLabel alloc] initWithText:localizedDisplayName];
        sectionViewLabel = [self.datasource designView:self sectionLabelViewForSectionAtIndex:sectionIndex];
        tapGestureRecognizer = [MADTapGestureRecognizer newTapGestureRecognizerSectionToggleWithTarget:self
                                                                                                action:@selector(handleTapLabel:)
                                                                                              delegate:self];
        [sectionLabelGestureRecognizers addObject:tapGestureRecognizer];
        [self.strayTouchGestureRecognizer requireGestureRecognizerToFail:tapGestureRecognizer];
        [sectionViewLabel addGestureRecognizer: tapGestureRecognizer];
        
        sectionViewLabel.tag = (NSInteger)sectionIndex;
        
        NSNumber *key;
        UIView *lastView;
        
        key = reportSectionKeyTracker.lastObject;
        lastView = sectionIndex == 0 ? self.ruler : sectionViewsDictionary[key];
        
        constraintViewTop = [MADLayoutConstraint newLayoutConstraintViewTop: lastView
                                                                 viewBottom: sectionView
                                                                    padding: MTReportDesignerBufferPaddingVertical];
        
        constraintViewHeight = [MADLayoutConstraint newLayoutConstraintView: sectionView
                                                                     height: sectionHeight];
        
        constraintLabelRight = [MADLayoutConstraint newLayoutConstraintLabelRight: sectionViewLabel
                                                                        container: sectionView
                                                                          padding: MTReportDesignerSectionLabelPaddingRight];
        
        constraintLabelBottom = [MADLayoutConstraint newLayoutConstraintLabelBottom: sectionViewLabel
                                                                          container: sectionView
                                                                            padding: MTReportDesignerBufferPaddingVertical];
        constraintLabelHeight = [MADLayoutConstraint newLayoutConstraintLabel: sectionViewLabel
                                                                     toHeight: MTReportDesignerSectionLabelHeight];
        
        constraintViewLeft = [MADLayoutConstraint newLayoutConstraintViewLeft:sectionView
                                                                      content:self
                                                                      padding:MTReportDesignerBorderPaddingSides];
        
        constraintViewRight = [MADLayoutConstraint newLayoutConstraintViewRight:sectionView
                                                                        content:self
                                                                        padding:MTReportDesignerBorderPaddingSides];
        
        collectionViewConstraints = [[NSArray alloc] initWithObjects: constraintViewLeft,
                                     constraintViewRight, nil];
        
        sectionViewLabelConstraints = [[NSArray alloc] initWithObjects: constraintViewTop,
                                       constraintViewHeight,
                                       constraintLabelRight,
                                       constraintLabelBottom,
                                       constraintLabelHeight, nil];
        
        [viewDidAppearDesignerContentViewConstraints addObjectsFromArray:sectionViewLabelConstraints];
        
        
        [constraintsSectionsVerticalBuffer addObject: constraintViewTop];
        [constraintSectionLabelHeightContainer addObject: constraintLabelHeight];
        
        [constraintsSectionsSidesBorder addObjectsFromArray:collectionViewConstraints];
        
        [scrollerLayoutConstraints addObjectsFromArray:collectionViewConstraints];

        NSNumber *sectionViewIdentifier = @(sectionView.identifier);
        constraintsReportSectionHeight[sectionViewIdentifier] = constraintViewHeight;
        
        sectionViewsDictionary[reportSectionKey] = sectionView;
        sectionControlViewsDictionary[reportSectionKey] = sectionViewLabel;
        
        [reportSectionKeyTracker addObject:reportSectionKey];
        
        [self addSubview:sectionView];
        [self addSubview:sectionViewLabel];
        
        [passthroughContainers addObject:sectionView];
        
        sectionView.sectionLabel = sectionViewLabel;
    }
    
    [reportSectionKeyTracker removeAllObjects];
    
    self.sectionLabelGestureRecognizers = sectionLabelGestureRecognizers;
    self.layoutConstraintsSectionsVerticalBuffer = constraintsSectionsVerticalBuffer;
    self.layoutConstraintsReportSectionHeight = constraintsReportSectionHeight;
    self.sectionViewsDictionary = sectionViewsDictionary;
    self.sectionControlViewsDictionary = sectionControlViewsDictionary;
    self.layoutConstraintsSectionsSidesBorder = constraintsSectionsSidesBorder;
    self.layoutConstraintSectionLabelHeightContainer = constraintSectionLabelHeightContainer;
    self.passthroughContainers = passthroughContainers;

    sectionHeights += MTReportDesignerBorderPaddingVertical;

    NSLayoutConstraint *constraintContentViewHeight;
    constraintContentViewHeight = [MADLayoutConstraint newLayoutConstraintView: self
                                                                        height: sectionHeights];

    [scrollerLayoutConstraints addObject:constraintContentViewHeight];
    self.layoutConstraintDesignerContentViewHeight = constraintContentViewHeight;

    
    NSLayoutConstraint *constraintToScollerBottom;
    constraintToScollerBottom = [MADLayoutConstraint newLayoutConstraintView: self
                                                             containerBottom: self.superview];
    
    [scrollerLayoutConstraints addObject:constraintToScollerBottom];
    
    [self.superview addConstraints: scrollerLayoutConstraints];
    [self addConstraints: viewDidAppearDesignerContentViewConstraints];
    
    self.viewDidAppearDesignerContentViewConstraints = viewDidAppearDesignerContentViewConstraints;
    self.viewDidAppearDesignerScrollViewConstraints = scrollerLayoutConstraints;
    

    
    
    _needsReload = NO;
    
}

- (void)reloadDataIfNeeded {
    if (_needsReload) [self reloadData];
}

- (void)handleTapLabel:(UITapGestureRecognizer *)sender {
    if (_delegateHas.handleTapLabel) [self.delegate designView:self handleTapLabel:sender];
}

- (void)handleTapStray:(UITapGestureRecognizer *)sender {
    if (_delegateHas.handleTapStray) [self.delegate designView:self handleTapStray:sender];
}

#pragma mark -
#pragma mark Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    //Require the failure of the resize handles.
    if ([otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] &&
        [otherGestureRecognizer respondsToSelector:@selector(handleGesturePanResizeHandle:)]) {
        return YES;
    } else {
        if (otherGestureRecognizer == self.strayTouchGestureRecognizer &&
            [gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] &&
            [self.sectionLabelGestureRecognizers containsObject:(UITapGestureRecognizer *)gestureRecognizer]) {
            return YES;
        } else {
            return  NO;
        }
    }
}

- (BOOL)gestureRecognizer: (UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch: (UITouch *)touch {
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
