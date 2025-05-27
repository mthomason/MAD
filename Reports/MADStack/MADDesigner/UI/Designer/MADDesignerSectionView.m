//
//  MTDocumentSectionView.m
//  Reports
//
//  Created by Michael Thomason on 2/11/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDesignerSectionView.h"
#import "MADDesignerSectionLayoutLiquid.h"
#import "UICollectionReusableView+Reuse.h"
#import "MTCollectionReuseableViewDefault.h"
#import "MADCellElement.h"
#import "MADDesignerSectionBackground.h"
#import "MADThemeManager.h"

#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import <UIKit/UIGraphics.h>
#import <UIKit/UIAccessibilityCustomAction.h>
#import <UIKit/UICollectionViewFlowLayout.h>
#import <UIKit/UIAccessibilityConstants.h>
#import <UIKit/UIGestureRecognizer.h>
#import <QuartzCore/CALayer.h>
#import <CoreData/NSManagedObjectID.h>

static inline UIColor *backgroundColor(BOOL selected, BOOL visible) {
	if (!selected && !visible) {
		return [MADColorEverydayApps newColorDisabledColor];
	} else if (selected && !visible) {
		return [MADColorEverydayApps newColorDisabledColor];
	} else if (selected && visible) {
		return [UIColor whiteColor];
	} else {
		return [UIColor whiteColor];
	}
}

static inline MADBorderState borderState(BOOL selected, BOOL visible) {
	if (selected) return MADBorderStateSelected;
	if (visible) return MADBorderStateNormal;
	return MADBorderStateDisabled;
}

@interface MADDesignerSectionView ()
@property (nonatomic, assign) CGFloat resizeHeightDifferenceInital;
@property (nonatomic, assign) CGFloat resizeHeightBoundsHeightInital;
@property (nonatomic, assign) BOOL accessibile;
@end

@implementation MADDesignerSectionView

- (void)dealloc {
	self.delegate = nil;
	self.dataSource = nil;
}


+ (instancetype)newDesignerSectionView:(NSInteger)identifier
				  designViewIdentifier:(NSUInteger)designViewIdentifier
							 isVisible:(BOOL)isVisible
							  delegate:(id <MADDesignerSectionLayoutLiquidDelegate, UICollectionViewDelegate, UICollectionViewDataSource>)layoutDelegate {
	
	MADDesignerSectionLayoutLiquid *layout = [[MADDesignerSectionLayoutLiquid alloc] init];
	layout.delegate = layoutDelegate;
	layout.designViewIdentifier = identifier;
	MADDesignerSectionView *collectionView = [[self alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
	collectionView.delegate = layoutDelegate;
	collectionView.dataSource = layoutDelegate;
	collectionView.identifier = identifier;
	collectionView.tag = identifier;
	collectionView.visible = isVisible;
	return collectionView;
}

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
	
	if (self = [super initWithFrame:frame collectionViewLayout:layout]) {

		self.accessibile = YES;
		
		MADDesignerSectionBackground *backgroundView = [[MADDesignerSectionBackground alloc] initWithFrame:CGRectZero];
		[backgroundView setNumberOfRowsInBackground:1];
		backgroundView.backgroundColor = [UIColor clearColor];

		NSString *supplmentaryViewReuseIdHeader = [MTCollectionReuseableViewDefault reuseIdentifier];
		NSString *documentElementReuseIdentifier = [MADCellElement reuseIdentifier];
		
		[self registerClass: [MADCellElement class] forCellWithReuseIdentifier: documentElementReuseIdentifier];
		
		[self registerClass: [MTCollectionReuseableViewDefault class] forSupplementaryViewOfKind: UICollectionElementKindSectionHeader withReuseIdentifier: supplmentaryViewReuseIdHeader];
		[self registerClass: [MTCollectionReuseableViewDefault class] forSupplementaryViewOfKind: UICollectionElementKindSectionFooter withReuseIdentifier: supplmentaryViewReuseIdHeader];
		
		self.clipsToBounds = YES;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.allowsSelection = YES;
		self.allowsMultipleSelection = YES;
		self.translatesAutoresizingMaskIntoConstraints = NO;

		UIColor *borderColor = [MADColorEverydayApps newColorBorderColor];
		self.layer.borderColor = borderColor.CGColor;
		self.backgroundView = nil;
		self.backgroundColor = [UIColor clearColor];
		self.layer.borderWidth = [MADThemeManager borderWidthThin];
		self.showsVerticalScrollIndicator = YES;

		[self setContentHuggingPriority: UILayoutPriorityDefaultLow
								forAxis: UILayoutConstraintAxisVertical];
		[self setContentCompressionResistancePriority: UILayoutPriorityDefaultHigh
											  forAxis: UILayoutConstraintAxisVertical];
		_selected = NO;
		_visible = NO;
	}
	
	return self;
	
}

#pragma mark -
#pragma mark UIView

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	CGContextRef context = UIGraphicsGetCurrentContext();
	UIColor *bgcolor = backgroundColor(self.selected, self.visible);
	CGContextSetFillColorWithColor(context, bgcolor.CGColor);
	CGContextFillRect(context, rect);
}

- (CGSize)intrinsicContentSize {
	return CGSizeMake(self.collectionViewLayout.collectionViewContentSize.width,
					  self.collectionViewLayout.collectionViewContentSize.height + MTDefaultFingerSizeHeight);
}

#pragma mark -
#pragma mark Delegates

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
	shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
	return YES;
	//[gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] &&
	//      [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]];
}

#pragma mark -
#pragma mark Accessors

- (void)removeItemAtIndex: (NSIndexPath *)deletePath update: (void (^)(void))update
		animationComplete: (void (^)(BOOL))animationComplete completion: (void (^)(void))completion {

	void (^updates)(void) = ^{
		
		if (update != nil) update();
		NSArray *indexPaths = [[NSArray alloc] initWithObjects:deletePath, nil];
		[self deleteItemsAtIndexPaths: indexPaths];
		
	};

	void (^complets)(BOOL) = ^(BOOL finished) {
		
		if (finished) {

			void (^animate)(void) = ^{
				[self invalidateIntrinsicContentSize];
			};

			void (^finish)(BOOL) = ^(BOOL animateFinished) {
				if (animateFinished) {
					if (animationComplete != nil) animationComplete(animateFinished);
				}
			};

			[UIView animateWithDuration: 0.6666f
							 animations: animate
							 completion: finish];
			if (completion != nil) { completion(); }
		}
	
	};

	[self performBatchUpdates:updates
				   completion:complets];
}

- (void)insertItemAtIndex: (NSIndexPath *)path update: (void (^)(void))update
		animationComplete: (void (^)(BOOL))animationComplete
			   completion: (void (^)(void))completion {
	
	[self performBatchUpdates:^(void) {
		
		if (update != nil) update();
		NSArray *indexPathsInserted = [[NSArray alloc] initWithObjects:path, nil];
		[self insertItemsAtIndexPaths: indexPathsInserted];
		
	} completion:^(BOOL finished) {
	
		if (finished) {
			[UIView animateWithDuration:(2.0/3.0) animations:^{
				[self invalidateIntrinsicContentSize];
			} completion:^(BOOL animateFinished) {
				if (animateFinished) {
					if (animationComplete != nil) animationComplete(YES);
				}
			}];
			
			if (completion != nil) { completion(); }
		}
		
	}];
}

- (void)setBorderState:(MADBorderState)borderState {
	switch (borderState) {
		case MADBorderStateDisabled:
			self.layer.borderColor = [UIColor blackColor].CGColor;
			self.layer.borderWidth = 1.0;
			break;
		case MADBorderStateNormal:
			self.layer.borderColor = [UIColor blackColor].CGColor;
			self.layer.borderWidth = 1.0;
			break;
		case MADBorderStateSelected:
			self.layer.borderColor = [MADColorEverydayApps newColorAnalogous4].CGColor;
			self.layer.borderWidth = 1.0;
			break;
		default:
			break;
	}
}

#pragma mark Overrides

- (void)setVisible:(BOOL)visible {
	if (_visible != visible) {
		_visible = visible;
		[self setBorderState:borderState(_selected, _visible)];
		[self setNeedsDisplay];
	}
}

- (void)setSelected:(BOOL)selected {
	if (_selected != selected) {
		_selected = selected;
		[self setBorderState:borderState(_selected, _visible)];
		[self setNeedsDisplay];
	}
}

/*

#pragma mark -
#pragma mark Accessibility

- (NSArray <__kindof UIAccessibilityCustomAction *> *)accessibilityCustomActions {
	UIAccessibilityCustomAction *toggleAccessibility = [[UIAccessibilityCustomAction alloc] initWithName: NSLocalizedString(@"Access section elements.", @"Access section elements.")
																								  target: self
																								selector: @selector(toggleAccessibility:)];
	return @[toggleAccessibility];
}

- (BOOL)isAccessibilityElement {
	return NO;
}

- (NSInteger)accessibilityElementCount {
	return [self.dataSource collectionView:self numberOfItemsInSection:0] + 1;
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
	return [element isKindOfClass:[UICollectionViewCell class]] ?
				[self indexPathForCell:element].item + 1 : 0;
}

- (id)accessibilityElementAtIndex:(NSInteger)index {
	if (index == 0) {
		return self.sectionLabel;
	} else {
		NSIndexPath *path = [NSIndexPath indexPathForItem:index + 1 inSection:0];
		return [self cellForItemAtIndexPath:path];
	}
}

- (UIAccessibilityTraits)accessibilityTraits {
	return UIAccessibilityTraitButton;
}

*/

@end
