//
//  MADDesignerLayoutDesignView.m
//  MAD Designer
//
//  Created by Michael on 5/26/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDesignerLayoutDesignView.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSSet.h>

#import "MADRulerView.h"
#import "NSLayoutConstraint+Designer.h"

#import "MADDesignerSectionView.h"
#import "MADDesignerSectionLabel.h"
#import "MADDesignerElementView.h"

#import "MADReportSectionDataSourceProtocol.h"
#import "MADReportSectionDelegateProtocol.h"

#import "UITapGestureRecognizer+Designer.h"

const CGFloat MTReportDesignerBorderPaddingDetail        =  3.0000f;
const CGFloat MTReportDesignerBorderPaddingVertical      =  3.0000f;
const CGFloat MTReportDesignerBorderPaddingSides         =  8.0000f;
const CGFloat MTReportDesignerBufferPaddingVertical      =  2.0000f;
const CGFloat MTReportDesignerSectionLabelPaddingRight   =  8.0000f;
const CGFloat MTReportDesignerSectionLabelHeight         = 20.0000f;

@interface MADDesignerLayoutDesignView () <UIGestureRecognizerDelegate>

	@property (readwrite, nonatomic, strong) NSMutableSet <NSNumber *> *selectedElements;
	@property (readwrite, nonatomic, strong) NSMutableSet <NSNumber *> *selectedSections;

	@property (readwrite, nonatomic, strong) NSLayoutConstraint *layoutConstraintDesignerContentViewHeight;

	@property (readwrite, nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *layoutConstraintsSectionsVerticalBuffer;
	@property (readwrite, nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *layoutConstraintsSectionsSidesBorder;
	@property (readwrite, nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *layoutConstraintSectionLabelHeightContainer;

	@property (readwrite, nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *rulerHorizontalConstraints;
	@property (readwrite, nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *rulerVerticalConstraints;
	@property (readwrite, nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *viewDidAppearDesignerScrollViewConstraints;
	@property (readwrite, nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *viewDidAppearDesignerContentViewConstraints;

	@property (readwrite, nonatomic, strong) NSMutableDictionary <NSNumber *, NSLayoutConstraint *> *layoutConstraintsReportSectionHeight;
	@property (readwrite, nonatomic, strong) NSMutableDictionary <NSNumber *, MADDesignerSectionView *> *sectionViews;
	@property (readwrite, nonatomic, strong) NSMutableDictionary <NSNumber *, MADDesignerSectionLabel *> *sectionLabels;

	@property (readwrite, nonatomic, strong) NSMutableSet <MADDesignerSectionView *> *passthroughContainers;
	@property (readwrite, nonatomic, strong) NSMutableSet <UITapGestureRecognizer *> *sectionLabelGestureRecognizers;

	@property (readwrite, nonatomic, strong) UITapGestureRecognizer *strayTouchGestureRecognizer;

@end

static inline UIEdgeInsets ScrollIndicatorContentInsets(CGRect presentedRect);
static inline UIEdgeInsets ScrollIndicatorContentInsets(CGRect presentedRect) {
	return UIEdgeInsetsMake(CGSizeZero.height, CGSizeZero.width,
							CGSizeZero.height,
							presentedRect.size.width - MTReportDesignerBorderPaddingSides);
}

@implementation MADDesignerLayoutDesignView {
	BOOL _needsReload;
	BOOL _needsCleanup;
	NSUInteger _numberOfSections;
	struct {
		BOOL handleTapLabel;
		BOOL handleTapStray;
	} _delegateHas;
	struct {
		BOOL numberOfSectionsInDesignView;
	} _dataSourceHas;
}

#pragma mark -
#pragma mark Constructors and destructors

- (void)dealloc {
	[self cleanup];
	if (_rulerVerticalConstraints.count > 0)
		[NSLayoutConstraint deactivateConstraints: _rulerVerticalConstraints];
	if (_rulerHorizontalConstraints.count > 0)
		[NSLayoutConstraint deactivateConstraints: _rulerHorizontalConstraints];

	[_ruler removeConstraints:_rulerVerticalConstraints];
	[_ruler removeConstraints:_rulerHorizontalConstraints];
	[_ruler removeFromSuperview];
	[_rulerHorizontalConstraints removeAllObjects];
	[_rulerVerticalConstraints removeAllObjects];
	_datasource = nil;
	_rulerVerticalConstraints = nil;
	_rulerVerticalConstraints = nil;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		[[self class] setup: &self];
	}
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		[[self class] setup: &self];
	}
	return self;
}

#pragma mark Common initalizer

+ (void)setup:(MADDesignerLayoutDesignView *__autoreleasing *)view {

	(*view)->_needsReload = YES;
	(*view)->_needsCleanup = NO;
	
	MADRulerView *ruler = [[MADRulerView alloc] initWithFrame:CGRectZero];
	
	NSArray <NSLayoutConstraint *> *rulerVerticalConstraints, *rulerHorizontalConstraints;
	rulerVerticalConstraints = [MADLayoutConstraint constraintForRuler: ruler
															  designer: *view
															 marginTop: MTReportDesignerBorderPaddingVertical
																 heigh: MTReportDesignerRulerHeight
														   scaleFactor: 1.0];
	
	rulerHorizontalConstraints = [MADLayoutConstraint constraintForRuler: ruler
																designer: *view
															  sideMargin: MTReportDesignerBorderPaddingSides
															 scaleFactor: 1.0];
	
	NSArray <NSLayoutConstraint *> *allConstraints = [rulerVerticalConstraints arrayByAddingObjectsFromArray:rulerHorizontalConstraints];
	
	[*view addSubview:ruler];
	[*view addConstraints:allConstraints];
	
	[(*view).rulerVerticalConstraints addObjectsFromArray: rulerVerticalConstraints];
	[(*view).rulerHorizontalConstraints addObjectsFromArray: rulerHorizontalConstraints];
	
	(*view).ruler = ruler;
	
	allConstraints = nil;
}

+ (NSArray *)constraintsForSectionView:(UIView *)sectionView contentView:(UIView *)contentView {
	id left = [MADLayoutConstraint newLayoutConstraintViewLeft:sectionView
													   content:contentView
													   padding:MTReportDesignerBorderPaddingSides];
	
	id right = [MADLayoutConstraint newLayoutConstraintViewRight:sectionView
														 content:contentView
														 padding:MTReportDesignerBorderPaddingSides];
	
	id results = [[NSArray alloc] initWithObjects: left, right, nil];
	return results;
}

#pragma mark -
#pragma mark Property overrides


- (void)updateConstraints {
	CGFloat zoomscale = [self.superview isKindOfClass:[UIScrollView class]] ?
							((UIScrollView *)self.superview).zoomScale : 1.0000f;
	void (^calculateBorder)(NSLayoutConstraint *, NSUInteger, BOOL *);
	void (^calculateVerticalBuffer)(NSLayoutConstraint *, NSUInteger, BOOL *);
	void (^calculateLabelHeight)(NSLayoutConstraint *, NSUInteger, BOOL *);
	
	calculateBorder = ^(NSLayoutConstraint *constraint, NSUInteger idx, BOOL *stop) {
		if (zoomscale != 0) {
			constraint.constant = constraint.constant > 0 ? MTReportDesignerBorderPaddingSides / zoomscale :
														   -MTReportDesignerBorderPaddingSides / zoomscale;
		} else {
			constraint.constant = 0;
		}
	};
	
	calculateVerticalBuffer = ^(NSLayoutConstraint * constraint, NSUInteger idx, BOOL *stop) {
		constraint.constant = constraint.constant > 0 ? MTReportDesignerBufferPaddingVertical :
													   -MTReportDesignerBufferPaddingVertical;
	};
	
	calculateLabelHeight = ^(NSLayoutConstraint * constraint, NSUInteger idx, BOOL *stop) {
		constraint.constant = MTReportDesignerSectionLabelHeight / zoomscale;
	};
	
	[self.layoutConstraintsSectionsSidesBorder enumerateObjectsUsingBlock:calculateBorder];
	[self.layoutConstraintsSectionsVerticalBuffer enumerateObjectsUsingBlock:calculateVerticalBuffer];
	[self.layoutConstraintSectionLabelHeightContainer enumerateObjectsUsingBlock:calculateLabelHeight];
	self.layoutConstraintDesignerContentViewHeight.constant = self.sizeHeight;

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

- (void)setNeedsCleanup {
	_needsCleanup = YES;
}

- (void)cleanup {
	
	if (!_needsCleanup) return;
	
	[NSLayoutConstraint deactivateConstraints: _viewDidAppearDesignerScrollViewConstraints];
	[NSLayoutConstraint deactivateConstraints: _viewDidAppearDesignerContentViewConstraints];
	
	[self removeConstraints: _viewDidAppearDesignerContentViewConstraints];
	[self.superview removeConstraints: _viewDidAppearDesignerScrollViewConstraints];
	
	NSEnumerator *sectionViews = _sectionViews.objectEnumerator;
	for (MADDesignerSectionView *view in sectionViews) {
		[view.sectionLabel removeFromSuperview];
		[view removeFromSuperview];
		view.sectionLabel = nil;
	}
	
	[_layoutConstraintsSectionsVerticalBuffer removeAllObjects];
	[_layoutConstraintsSectionsSidesBorder removeAllObjects];
	[_layoutConstraintSectionLabelHeightContainer removeAllObjects];
	
	[_layoutConstraintsReportSectionHeight removeAllObjects];
	[_sectionViews removeAllObjects];
	[_sectionLabels removeAllObjects];
	
	[_passthroughContainers removeAllObjects];
	[_sectionLabelGestureRecognizers removeAllObjects];
	
	[_viewDidAppearDesignerScrollViewConstraints removeAllObjects];
	[_viewDidAppearDesignerContentViewConstraints removeAllObjects];

	_needsCleanup = NO;
}

- (void)removeBorderFromAllSectionViews {
	NSEnumerator <MADDesignerSectionLabel *> *labels;
	labels = self.sectionLabels.objectEnumerator;
	for (MADDesignerSectionLabel *label in labels) {
		[self removeBorderFromSectionLabel: label];
	}
}

- (BOOL)removeBorderFromSectionLabel:(MADDesignerSectionLabel *)label {
	BOOL result;
	NSNumber *key = [[NSNumber alloc] initWithInteger:label.tag];
	if ([self.selectedSections containsObject:key]) {
		[self.selectedSections removeObject:key];
		[label removeBorder];
		result = YES;
	} else {
		result = NO;
	}
	return result;
}

- (void)applyBorderToSectionLabel:(MADDesignerSectionLabel *)view {
	
	NSNumber *key = [[NSNumber alloc] initWithInteger: view.tag];
	[self.selectedSections addObject:key];
	[view applyBorder];
}

- (BOOL)removeBorderFromView:(MADDesignerElementView *)view {
	BOOL result;
	if ([self.selectedElements containsObject:view.key]) {
		[self.selectedElements removeObject:view.key];
		result = YES;
		[view removeBorder];
	} else {
		result = NO;
	}
	return result;
}

- (void)applyBorderToView:(MADDesignerElementView *)view {
	[self.selectedElements addObject:view.key];
	[view applyBorder];
}

// Called to update the view.

- (void)reloadData {
	
	if (_datasource == nil) return;
	
	[self cleanup];
	
	id <MADDesignerDesignViewDataSource> datasource = _datasource;
	CGFloat measurementSectionHeight;

	_numberOfSections = _dataSourceHas.numberOfSectionsInDesignView ?
							[datasource numberOfSectionsInDesignView:self] : 0;
	
	NSMutableSet <MADDesignerSectionView *> *passthroughContainers;
	passthroughContainers = [[NSMutableSet alloc] initWithCapacity:_numberOfSections];
	
	[self.viewDidAppearDesignerScrollViewConstraints addObjectsFromArray:self.rulerHorizontalConstraints];
	[self.viewDidAppearDesignerScrollViewConstraints addObjectsFromArray:self.rulerVerticalConstraints];
	[self.layoutConstraintsSectionsSidesBorder addObjectsFromArray:self.rulerHorizontalConstraints];
	
	CGFloat measurementControlHeight = CGSizeZero.height + MTReportDesignerRulerHeight +
														   MTReportDesignerBorderPaddingVertical;
	
	NSLayoutConstraint *constraintViewTop, *constraintViewHeight, *constraintLabelRight,
					   *lcLabelBottom, *lcLabelHeight;
	
	NSArray *collectionViewConstraints;
	NSArray *sectionViewLabelConstraints;
	
	NSMutableSet <UITapGestureRecognizer *> *sectionLabelGestureRecognizers = [[NSMutableSet alloc] init];
	MADDesignerSectionView *sectionView;
	MADDesignerSectionLabel *sectionViewLabel;
	UITapGestureRecognizer *tapGestureRecognizer;
	
	NSNumber *reportSectionKey, *lastReportSectionKey = nil;
	for (NSUInteger sectionIndex = 0; sectionIndex < _numberOfSections; sectionIndex++) {

		measurementSectionHeight = [datasource designView:self heightForSectionAtIndex:sectionIndex];
		measurementControlHeight += MTReportDesignerBufferPaddingVertical + measurementSectionHeight;
		reportSectionKey = [datasource sectionKey:sectionIndex];
		
		// Get new section view.
		sectionView = [datasource designView:self sectionViewForSectionAtIndex:sectionIndex];
		
		// Get new section label.
		sectionViewLabel = [self.datasource designView:self sectionLabelViewForSectionAtIndex:sectionIndex];
		sectionViewLabel.userInteractionEnabled = YES;
		tapGestureRecognizer = [MADTapGestureRecognizer newTapGestureRecognizerSectionToggleWithTarget:self
																								action:@selector(handleTapLabel:)
																							  delegate:self];
		[sectionLabelGestureRecognizers addObject:tapGestureRecognizer];
		[self.strayTouchGestureRecognizer requireGestureRecognizerToFail:tapGestureRecognizer];
		[sectionViewLabel addGestureRecognizer: tapGestureRecognizer];
		
		sectionViewLabel.tag = (NSInteger)sectionIndex;
		
		constraintViewTop = [MADLayoutConstraint newLayoutConstraintViewTop: sectionIndex == 0 ? self.ruler : self.sectionViews[lastReportSectionKey]
																 viewBottom: sectionView
																	padding: MTReportDesignerBufferPaddingVertical];
		
		constraintViewHeight = [MADLayoutConstraint newLayoutConstraintView: sectionView
																	 height: measurementSectionHeight];
		
		constraintLabelRight = [MADLayoutConstraint newLayoutConstraintLabelRight: sectionViewLabel container: sectionView
																		  padding: MTReportDesignerSectionLabelPaddingRight];
		
		lcLabelBottom = [MADLayoutConstraint newLayoutConstraintLabelBottom: sectionViewLabel container: sectionView
																			padding: MTReportDesignerBufferPaddingVertical];
		
		lcLabelHeight = [MADLayoutConstraint newLayoutConstraintLabel: sectionViewLabel toHeight: MTReportDesignerSectionLabelHeight];
		
		collectionViewConstraints = [MADDesignerLayoutDesignView constraintsForSectionView:sectionView contentView:self];
		
		sectionViewLabelConstraints = [[NSArray alloc] initWithObjects: constraintViewTop,
									   constraintViewHeight, constraintLabelRight,
									   lcLabelBottom, lcLabelHeight, nil];
		
		[self.viewDidAppearDesignerScrollViewConstraints addObjectsFromArray:collectionViewConstraints];
		[self.layoutConstraintsSectionsVerticalBuffer addObject: constraintViewTop];
		[self.layoutConstraintSectionLabelHeightContainer addObject: lcLabelHeight];
		[self.layoutConstraintsSectionsSidesBorder addObjectsFromArray:collectionViewConstraints];
		[self.viewDidAppearDesignerContentViewConstraints addObjectsFromArray:sectionViewLabelConstraints];

		NSNumber *sectionViewIdentifier = @(sectionView.identifier);
		self.layoutConstraintsReportSectionHeight[sectionViewIdentifier] = constraintViewHeight;
		
		self.sectionViews[reportSectionKey] = sectionView;
		self.sectionLabels[reportSectionKey] = sectionViewLabel;
		
		[self addSubview:sectionView];
		[self addSubview:sectionViewLabel];
		
		[passthroughContainers addObject:sectionView];
		
		sectionView.sectionLabel = sectionViewLabel;

		lastReportSectionKey = reportSectionKey.copy;
	}
	
	
	self.sectionLabelGestureRecognizers = sectionLabelGestureRecognizers;
	self.passthroughContainers = passthroughContainers;

	measurementControlHeight += MTReportDesignerBorderPaddingVertical;

	NSLayoutConstraint *constraintContentViewHeight;
	constraintContentViewHeight = [MADLayoutConstraint newLayoutConstraintView: self
																		height: measurementControlHeight];

	[self.viewDidAppearDesignerScrollViewConstraints addObject:constraintContentViewHeight];
	self.layoutConstraintDesignerContentViewHeight = constraintContentViewHeight;

	
	NSLayoutConstraint *constraintToScollerBottom;
	constraintToScollerBottom = [MADLayoutConstraint newLayoutConstraintView: self
															 containerBottom: self.superview];
	
	[self.viewDidAppearDesignerScrollViewConstraints addObject:constraintToScollerBottom];
	
	[self.superview addConstraints: self.viewDidAppearDesignerScrollViewConstraints];
	[self addConstraints: self.viewDidAppearDesignerContentViewConstraints];
	
	_needsReload = NO;
	_needsCleanup = YES;
}

- (MADDesignerSectionView *)sectionViewDetail {
	NSNumber *identifier = [self.datasource sectionKeyDetail];
	return self.sectionViews[identifier];
}

- (MADDesignerSectionLabel *)sectionLabelDetail {
	NSNumber *identifier = [self.datasource sectionKeyDetail];
	return self.sectionLabels[identifier];
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

#pragma mark -
#pragma mark Property overrides

- (void)setDatasource:(NSObject<MADDesignerDesignViewDataSource> *)datasource {
	_dataSourceHas.numberOfSectionsInDesignView = [datasource respondsToSelector:@selector(numberOfSectionsInDesignView:)];
	_datasource = datasource;
}

- (void)setDelegate:(id <MADDesignerDesignViewDelegate>)delegate {
	_delegateHas.handleTapLabel = [delegate respondsToSelector:@selector(designView:handleTapLabel:)];
	_delegateHas.handleTapStray = [delegate respondsToSelector:@selector(designView:handleTapStray:)];
	_delegate = delegate;
}

#pragma mark -
#pragma mark Lazy load

- (NSMutableSet <NSNumber *> *)selectedElements {
	if (!_selectedElements) {
		NSMutableSet *selectedElements = [[NSMutableSet alloc] init];
		_selectedElements = selectedElements;
	}
	return _selectedElements;
}

- (NSMutableSet <NSNumber *> *)selectedSections {
	if (!_selectedSections) {
		NSMutableSet *selectedSections = [[NSMutableSet alloc] init];
		_selectedSections = selectedSections;
	}
	return _selectedSections;
}

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

- (NSMutableArray <NSLayoutConstraint *> *)rulerVerticalConstraints {
	if (_rulerVerticalConstraints == nil) {
		_rulerVerticalConstraints = [[NSMutableArray alloc] initWithCapacity: 2];;
	}
	return _rulerVerticalConstraints;
}

- (NSMutableArray <NSLayoutConstraint *> *)rulerHorizontalConstraints {
	if (_rulerHorizontalConstraints == nil) {
		_rulerHorizontalConstraints = [[NSMutableArray alloc] initWithCapacity: 2];;
	}
	return _rulerHorizontalConstraints;
}

- (NSMutableArray <NSLayoutConstraint *> *)layoutConstraintsSectionsVerticalBuffer {
	if (_layoutConstraintsSectionsVerticalBuffer == nil) {
		_layoutConstraintsSectionsVerticalBuffer = [[NSMutableArray alloc] initWithCapacity: _numberOfSections];
	}
	return _layoutConstraintsSectionsVerticalBuffer;
}

- (NSMutableArray <NSLayoutConstraint *> *)layoutConstraintsSectionsSidesBorder {
	if (_layoutConstraintsSectionsSidesBorder == nil) {
		_layoutConstraintsSectionsSidesBorder = [[NSMutableArray alloc] initWithCapacity: _numberOfSections * 2 + 2];
	}
	return _layoutConstraintsSectionsSidesBorder;
}

- (NSMutableArray <NSLayoutConstraint *> *)layoutConstraintSectionLabelHeightContainer {
	if (_layoutConstraintSectionLabelHeightContainer == nil) {
		_layoutConstraintSectionLabelHeightContainer = [[NSMutableArray alloc] initWithCapacity: _numberOfSections];
	}
	return _layoutConstraintSectionLabelHeightContainer;
}

- (NSMutableArray <NSLayoutConstraint *> *)viewDidAppearDesignerScrollViewConstraints {
	if (_viewDidAppearDesignerScrollViewConstraints == nil) {
		_viewDidAppearDesignerScrollViewConstraints = [[NSMutableArray alloc] initWithCapacity:_numberOfSections * 2 + 6];
	}
	return _viewDidAppearDesignerScrollViewConstraints;
}

- (NSMutableArray <NSLayoutConstraint *> *)viewDidAppearDesignerContentViewConstraints {
	if (_viewDidAppearDesignerContentViewConstraints == nil) {
		_viewDidAppearDesignerContentViewConstraints = [[NSMutableArray alloc] initWithCapacity:_numberOfSections * 5];
	}
	return _viewDidAppearDesignerContentViewConstraints;
}

- (NSMutableDictionary <NSNumber *, NSLayoutConstraint *> *)layoutConstraintsReportSectionHeight {
	if (_layoutConstraintsReportSectionHeight == nil) {
		_layoutConstraintsReportSectionHeight = [[NSMutableDictionary alloc] initWithCapacity: _numberOfSections];
	}
	return _layoutConstraintsReportSectionHeight;
}

- (NSMutableDictionary <NSNumber *, MADDesignerSectionView *> *)sectionViews {
	if (_sectionViews == nil) {
		_sectionViews = [[NSMutableDictionary alloc] initWithCapacity: _numberOfSections];
	}
	return _sectionViews;
}

- (NSMutableDictionary <NSNumber *, MADDesignerSectionLabel *> *)sectionLabels {
	if (_sectionLabels == nil) {
		_sectionLabels = [[NSMutableDictionary alloc] initWithCapacity: _numberOfSections];
	}
	return _sectionLabels;
}


#pragma mark -
#pragma mark Helpers

- (void)removeBorderFromSections {
	//Remove border from the section views
	[_sectionLabels enumerateKeysAndObjectsUsingBlock:^(id key, MADDesignerSectionLabel *view, BOOL *stop) {
		[view normalView];
	}];
	
	//Remove border from the section views
	[_sectionViews enumerateKeysAndObjectsUsingBlock:^(id key, MADDesignerSectionView *view, BOOL *stop) {
		view.selected = NO;
	}];
}

- (void)repositionSectionViews:(CGRect)presentedRect {
	if (presentedRect.origin.x > CGPointZero.x) {
		NSEnumerator <MADDesignerSectionView *> *sectionViews = self.sectionViews.objectEnumerator;
		for (UICollectionView *sectionView in sectionViews) {
			sectionView.contentInset = ScrollIndicatorContentInsets(presentedRect);
			sectionView.scrollIndicatorInsets = ScrollIndicatorContentInsets(presentedRect);
		}
	}
}

- (CGRect)popoverRectForSelectedViews:(NSSet <UIView *> *)views {
	CGRect result;
	if (views.count == 0) {
		result = CGRectZero;
	} else if (views.count == 1) {
		result = [views.anyObject convertRect:views.anyObject.frame toView:self];
	} else {
		CGRect frame;
		CGPoint min = CGPointZero, max = CGPointZero;
		NSUInteger counter = 0;
		for (UIView *elementView in views) {
			frame = [elementView convertRect: elementView.frame toView: self];
			if (counter == 0) {
				min = frame.origin;
				max = CGPointMake(frame.origin.x + frame.size.width,
								  frame.origin.y + frame.size.height);
			} else {
				min = CGPointMake(min.x < frame.origin.x ? min.x : frame.origin.x,
								  min.y < frame.origin.y ? min.y : frame.origin.y);
				max = CGPointMake(max.x > frame.origin.x + frame.size.width ? max.x : frame.origin.x + frame.size.width,
								  max.y > frame.origin.y + frame.size.height ? max.y : frame.origin.y + frame.size.height);
			}
			counter++;
		}
		result = CGRectMake(min.x, min.y, max.x - min.x, max.y - min.y);
	}
	return result;
}

- (CGFloat)sizeHeight {
	CGFloat height = CGPointZero.y + (self.sectionViews.count + 2) * MTReportDesignerBufferPaddingVertical +
							self.ruler.intrinsicContentSize.height;
	MADDesignerSectionView *sectionView;
	NSEnumerator <MADDesignerSectionView *> *sectionViews = self.sectionViews.objectEnumerator;
	for (sectionView in sectionViews) {
		height += sectionView.frame.size.height <= CGSizeZero.height ?
							ceil(sectionView.intrinsicContentSize.height) : sectionView.frame.size.height;
	}
	return height + 20.0000f;
}

- (void)updateSection:(NSNumber *)sectionKey height:(CGFloat)height {
	NSLayoutConstraint *layoutConstraint;
	layoutConstraint = self.layoutConstraintsReportSectionHeight[sectionKey];
	layoutConstraint.constant = height;
}

- (CGFloat)heightForSection:(NSNumber *)sectionID {
	NSLayoutConstraint *layoutConstraint = self.layoutConstraintsReportSectionHeight[sectionID];
	return layoutConstraint.constant;
}

@end
