//
//  DataObject.m
//  Reports
//
//  Created by Michael Thomason on 2/16/12.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADDesignerElementView.h"

#import "MADElementCanvas.h"
#import "MADResizeHandles.h"
#import "MADResizeHandleView.h"
#import "UITapGestureRecognizer+Designer.h"
#import "UIView+Extras.h"
#import "madlog.h"

#import <MADCocoaExtensions/MADViewHelpers.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/MADTextStyle.h>

#import <MAD/RptqRect+Extras.h>
#import <MAD/RptqAlignment.h>
#import <MAD/RptqTextStyle.h>
#import <MAD/RptqSize.h>
#import <MAD/RptqBorder.h>
#import <MAD/RptqDirectionalAsymmetry.h>
#import <MAD/RptqDocumentElement.h>
#import <MAD/RptqDocumentElement+Extras.h>
#import <MAD/RptqDocumentElementImage.h>
#import <MAD/RptqDocumentElementBarcode.h>
#import <MAD/RptqDocumentElementBarcode+Extras.h>
#import <MAD/MADElementStylizedText.h>
#import <MAD/MADAlignment.h>

#import <UIKit/NSParagraphStyle.h>
#import <UIKit/UIGraphics.h>

#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreGraphics/CGContext.h>

#import <QuartzCore/CALayer.h>

#define degreesToRadians(x) (M_PI * (x) / 180.0)
#define kAnimationRotateDeg 1.0
#define kAnimationTranslateX 2.0
#define kAnimationTranslateY 2.0

static const UIViewAnimationOptions MADViewAnimationOptionsWobble = (UIViewAnimationOptions)
													(UIViewAnimationOptionAllowUserInteraction |
														UIViewAnimationOptionRepeat |
														UIViewAnimationOptionAutoreverse);

#pragma mark - MTElementView

@interface MADDesignerElementView ()
	<MADElementCanvasDelegate, UIGestureRecognizerDelegate>

	@property (nonatomic, readwrite, strong) MADResizeHandles *resizeHandles;
	@property (nonatomic, readwrite, weak) NSManagedObjectContext *managedObjectContext;
	@property (nonatomic, readwrite, copy) NSManagedObjectID *objectID;
	@property (nonatomic, readwrite, copy) NSString *textRepresentation;

@end

@implementation MADDesignerElementView

@synthesize identifier = _identifier;
@synthesize displayWobbling = _displayWobbling;
@synthesize enableResizing = _enableResizing;
@synthesize displayHighlighted = _displayHighlighted;

- (void)dealloc {
	if (_resizeHandles) {
		UIView *view;
		for (view in _resizeHandles.resizeHandles) {
			[view removeFromSuperview];
		}
	}
}

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		self.translatesAutoresizingMaskIntoConstraints = YES;
		self.backgroundColor = [UIColor clearColor];
		self.clipsToBounds = NO;
		self.autoresizingMask = MADViewAutoresizingFlexable();
		self.displayWobbling = NO;
		self.displayHighlighted = NO;
		
		MADResizeHandles *resizeHandles = [[MADResizeHandles alloc] init];
		for (UIView *view in resizeHandles.resizeHandles) {
			[self addSubview:view];
		}
		self.resizeHandles = resizeHandles;
	}
	return self;
}

#pragma mark -
#pragma mark NSObject

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
	shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
	return [gestureRecognizer respondsToSelector:@selector(handleGesturePanResizeHandle:)] ||
		[otherGestureRecognizer respondsToSelector:@selector(handleGesturePanResizeHandle:)] ?
			YES : NO;
}

- (BOOL)gestureRecognizer: (UIGestureRecognizer *)gestureRecognizer
	   shouldReceiveTouch: (UITouch *)touch {
	return YES;
}

#pragma mark -
#pragma mark UIView

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	
	static const CGFloat kDashedBorderWidth     = (0.5000f);
	static const CGFloat kDashedPhase           = (0.0000f);
	static const CGFloat kDashedLinesLength[]   = {4.0000f, 2.0000f};
	static size_t const kDashedCount            = (2.0000f);
	
	RptqDocumentElement *element = (RptqDocumentElement *)[self.managedObjectContext objectWithID:self.objectID];
	
	UIColor *tintColor = [UIColor blackColor];
	
	//Draw element margin border.
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(context, kDashedBorderWidth);
	CGContextSetStrokeColorWithColor(context, tintColor.CGColor);
	CGContextSetLineDash(context, kDashedPhase, kDashedLinesLength, kDashedCount);
	CGContextAddRect(context, rect);
	CGContextStrokePath(context);
	
	//Draw border top
	UIColor *borderColor = [UIColor blackColor];
	if (element.border.width.top > CGSizeZero.height) {
		CGContextSetLineDash(context, kDashedPhase, nil, 0);
		CGContextSetLineWidth(context, element.border.width.top);
		CGContextAddLines(context, ((CGPoint[]){
			CGPointMake([element borderLineTopAX],
						[element borderLineTopAY] + (element.border.width.top / 2.0000f)),
			CGPointMake([element borderLineTopBX],
						[element borderLineTopBY] + (element.border.width.top / 2.0000f)),
		}), 2);
		CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
		CGContextStrokePath(context);
	}

	//Draw border bottom
	if (element.border.width.bottom > CGSizeZero.height) {
		CGContextSetLineDash(context, kDashedPhase, nil, 0);
		CGContextSetLineWidth(context, element.border.width.bottom);
		CGContextAddLines(context, ((CGPoint[]){
			CGPointMake([element borderLineBottomAX],
						[element borderLineBottomAY] - (element.border.width.bottom / 2.0000f)),
			CGPointMake([element borderLineBottomBX],
						[element borderLineBottomBY] - (element.border.width.bottom / 2.0000f)),
		}), 2);
		CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
		CGContextStrokePath(context);
	}

	//Draw border left
	if (element.border.width.left > CGSizeZero.width) {
		CGContextSetLineDash(context, kDashedPhase, nil, 0);
		CGContextSetLineWidth(context, element.border.width.left);
		CGContextAddLines(context, ((CGPoint[]){
			CGPointMake([element borderLineLeftAX] + (element.border.width.left / 2.0000f),
						[element borderLineLeftAY]),
			CGPointMake([element borderLineLeftBX] + (element.border.width.left / 2.0000f),
						[element borderLineLeftBY]),
		}), 2);
		CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
		CGContextStrokePath(context);
	}

	//Draw border right
	if (element.border.width.right > CGSizeZero.width) {
		CGContextSetLineDash(context, kDashedPhase, nil, 0);
		CGContextSetLineWidth(context, element.border.width.right);
		CGContextAddLines(context, ((CGPoint[]){
			CGPointMake([element borderLineRightAX] - (element.border.width.right / 2.0000f),
						[element borderLineRightAY]),
			CGPointMake([element borderLineRightBX] - (element.border.width.right / 2.0000f),
						[element borderLineRightBY]),
		}), 2);
		CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
		CGContextStrokePath(context);
	}


	tintColor = [UIColor lightGrayColor];
	//Draw element content view.
	CGContextSetStrokeColorWithColor(context, tintColor.CGColor);
	CGContextSetLineWidth(context, 1);
	CGContextSetLineDash(context, kDashedPhase, kDashedLinesLength, kDashedCount);
	CGContextAddRect(context, [element innerRect]);
	CGContextStrokePath(context);

	//tintColor = [UIColor grayColor];
	//Draw element content view.
	//CGContextSetStrokeColorWithColor(context, tintColor.CGColor);
	//CGContextSetLineWidth(context, 1);
	//CGContextSetLineDash(context, kDashedPhase, kDashedLinesLength, kDashedCount);
	//CGContextAddRect(context, [element paddingRect]);
	//CGContextStrokePath(context);

}

- (void)layoutSubviews {
	[super layoutSubviews];
	[self.resizeHandles positionAroundRect:self.frame];
}

- (void)setAlpha:(CGFloat)alpha {
	super.alpha = alpha;
	
	UIColor *labelBackgroundColor = [[UIColor alloc] initWithRed: 1.0000f
														   green: 1.0000f
															blue: 1.0000f
														   alpha: alpha];
	self.backgroundColor = labelBackgroundColor;
}

#pragma mark -
#pragma mark Accessors

- (void)showResizeHandles { }

- (void)hideResizeHandles {
	id resizeView;
	for (resizeView in self.resizeHandles.resizeHandles) {
		((UIView *)resizeView).hidden = YES;
	}
}

- (void)flash:(void (^)(BOOL finished))completion {
	void (^animates)(void);
	animates = ^{
		self.backgroundColor = [[MADColorEverydayApps newColorBlue] colorWithAlphaComponent:0.33333333f];
	};
	void (^handleAnimatesCompletion)(BOOL);
	handleAnimatesCompletion = ^(BOOL finished) {
		if (finished) self.backgroundColor = [UIColor clearColor];
		completion(finished);
	};
	[UIView animateWithDuration: 0.6666f
						  delay: 0.3333f
						options: UIViewAnimationOptionAutoreverse
					 animations: animates
					 completion: handleAnimatesCompletion];
}

- (void)setWobbleRunning:(BOOL)running {
	self.displayWobbling = running;
	if (running) {
		NSInteger randomInt = arc4random() % 500;
		float r = (randomInt / 500.0000f) + 0.5000f;
		
		self.transform = CGAffineTransformMakeRotation((CGFloat)degreesToRadians( (kAnimationRotateDeg * -1.0) - r ));
		CGAffineTransform rightWobble = CGAffineTransformMakeRotation((CGFloat)degreesToRadians( kAnimationRotateDeg + r ));
		
		self.layer.anchorPoint = CGPointMake(0.5000f, 0.5000f);

		[UIView animateWithDuration:0.3500
							  delay:0
							options: UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
						 animations: ^{
			self.transform = rightWobble;
		} completion:nil];
		
	} else {
		[self.layer removeAllAnimations];
		self.transform = CGAffineTransformIdentity;
	}
}

- (void)setEnableResizing:(BOOL)enableResizing {
	if (_enableResizing != enableResizing) {
		_enableResizing = enableResizing;
		if (enableResizing) [self showResizeHandles];
		else [self hideResizeHandles];
	}
}

- (void)resize:(CGSize)size {

	NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
	RptqDocumentElement *documentObject = [managedObjectContext objectWithID:self.objectID];
	[documentObject setSizeValue:size];

	if ([managedObjectContext hasChanges]) {
		NSError *saveError = NULL;
		[managedObjectContext save:&saveError];
		if (saveError != nil) {
			os_log_error(GetDesignerLog(), "%s: Error saving managed object context. %@", __PRETTY_FUNCTION__, saveError);
		}
	}
}

- (void)applyBorder {
	self.enableResizing = YES;
	UIColor *tintColor = [MADColorEverydayApps newColorAnalogous4];
	self.layer.borderColor = tintColor.CGColor;
	self.layer.borderWidth = [UIView borderWidthThin];
}

- (void)removeBorder {
	self.enableResizing = NO;
	UIColor *color = [UIColor blackColor];
	self.layer.borderColor = color.CGColor;
	self.layer.borderWidth = 0;
}

#pragma mark -
#pragma mark Update model

- (void)updateWithElement:(RptqDocumentElement *)element {
	if (element != nil) {
		
		self.frame = [element boundsCalculated];
		
		NSString *textRepresentation = [element designerRepresentationText];
		self.textRepresentation = textRepresentation.copy;
		
	}
}

- (void)updateSetMarginTop:(float)value {
	
}
- (void)updateSetMarginBottom:(float)value {
	
}
- (void)updateSetMarginLeft:(float)value {
	
}
- (void)updateSetMarginRight:(float)value {
	
}

#pragma mark -
#pragma mark Event Handlers

- (void)updateForManagedObjectContent:(NSManagedObjectContext *)context {
	RptqDocumentElement *element = (RptqDocumentElement *)[context objectWithID:self.objectID];
	[self updateWithElement:element];
	self.managedObjectContext = context;
}

- (void)handleGesturePanResizeHandle:(UIPanGestureRecognizer *)gestureRecognizer {
	UIView *piece = nil;
	if ([piece isKindOfClass:[MADResizeHandleView class]]) {
		[self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
		if (gestureRecognizer.state == UIGestureRecognizerStateBegan
								|| gestureRecognizer.state == UIGestureRecognizerStateChanged) {
			CGPoint translation = [gestureRecognizer translationInView:piece.superview];
			switch (((MADResizeHandleView *)piece).type) {
				case north:
				case south:
					[self resize:CGSizeMake(self.frame.size.width,
											self.frame.size.width + translation.y)];
					break;
				case east:
				case west:
					[self resize:CGSizeMake(self.frame.size.width + translation.x,
											self.frame.size.width)];
					break;
				case northWest:
				case northEast:
				case southEast:
				case southWest:
				default:
					[self resize:CGSizeMake(self.frame.size.width + translation.x,
											self.frame.size.width + translation.y)];
					break;
			}
			[gestureRecognizer setTranslation:CGPointZero inView:piece.superview];
		}
	}
}

- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		CGPoint locationInView = [gestureRecognizer locationInView:gestureRecognizer.view];
		gestureRecognizer.view.layer.anchorPoint =
				CGPointMake(locationInView.x / gestureRecognizer.view.bounds.size.width,
							locationInView.y / gestureRecognizer.view.bounds.size.height);
		gestureRecognizer.view.center =
				[gestureRecognizer locationInView:gestureRecognizer.view.superview];
	}
}

- (id <NSCopying>)key {
	return @(self.identifier);
}

- (void)removeFromSuperview {
	[super removeFromSuperview];
}

#pragma mark -
#pragma mark Standard

- (id)debugQuickLookObject {
	return self;
}

@end
