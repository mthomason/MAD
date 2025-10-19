//
//  fontSettingsTableViewController.m
//  Reports
//
//  Created by Michael Thomason on 1/5/12.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADToolboxStyleViewController.h"
#import "MADControlState.h"
#import "MADReportDesignerFontSelectorDelegateProtocol.h"
#import "MADDesignerDisplayProtocol.h"
#import "MADFontSelectorViewController.h"

#import <MADCocoaExtensions/MADBorderStyle.h>
#import <MADCocoaExtensions/MADMargin.h>
#import <MADCocoaExtensions/MADPadding.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/MADViewHelpers.h>

#import <MAD/MADocument.h>
#import <MAD/MADFont.h>
#import <MAD/MADAlignment.h>
#import <MAD/RptqRect.h>
#import <MAD/RptqBorder.h>
#import <MAD/RptqSize.h>
#import <MAD/RptqAlignment.h>
#import <MAD/RptqDocumentElement.h>
#import <MAD/RptqDocumentElement+Extras.h>
#import <MAD/RptqDirectionalAsymmetry.h>
#import <MAD/RptqTextStyle.h>
#import <MAD/MADDesignerLayout.h>

#import <UIKit/NSAttributedString.h>
#import <UIKit/UIStepper.h>
#import <UIKit/UISegmentedControl.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIButton.h>
#import <UIKit/UIImageView.h>
#import <UIKit/UIStoryboardSegue.h>
#import <UIKit/UINibDeclarations.h>
#import <QuartzCore/CALayer.h>
#import <CoreData/NSManagedObjectContext.h>
#import <asl.h>

static const CGFloat CornerRadius = 6.6666f;
static const CGFloat BorderWidth = 1.0000f;

static NSString * const MADIdentifierStoryboardSeguePushFontPicker = @"MADIdentifierStoryboardSeguePushFontPicker";

static inline BOOL ControlStateIsOn(MTControlState controlState);
static inline BOOL ControlStateIsOn(MTControlState controlState) {
    return controlState == MTControlStateOn;
}

@interface MADToolboxStrings : NSAttributedString

+ (NSAttributedString *)systemString:(NSString *)string;
+ (NSAttributedString *)boldSystemString:(NSString *)string;
+ (NSAttributedString *)stringForSubject:(NSString *)subject value:(NSString *)value;
+ (NSAttributedString *)sizeWidthForValue:(double)value;
+ (NSAttributedString *)sizeHeightForValue:(double)value;
+ (NSAttributedString *)marginTopForValue:(double)value;
+ (NSAttributedString *)marginBottomForValue:(double)value;
+ (NSAttributedString *)marginLeftForValue:(double)value;
+ (NSAttributedString *)marginRightForValue:(double)value;
+ (NSAttributedString *)attributedStringFontSizeInPoints:(double)pointsDisplay
											withFontSize:(CGFloat)pointSize;

@end

@interface MADToolboxStyleViewController () <UITableViewDelegate>

@property (nonatomic, assign) MTControlState controlStateBold;
@property (nonatomic, assign) MTControlState controlStateItalic;
@property (nonatomic, assign) MTControlState controlStateStrike;
@property (nonatomic, assign) MTControlState controlStateUnderline;

@property (nonatomic, strong) NSSet <NSNumber *> *userSelectedObjectIDs;

@property (nonatomic, weak) IBOutlet UITableViewCell *fontLabelTableViewCell;
@property (nonatomic, weak) IBOutlet UILabel *labelFontSize;

// These next for labels represent section headers.
@property (weak, nonatomic) IBOutlet UILabel *labelHeaderPadding;
@property (weak, nonatomic) IBOutlet UILabel *labelHeaderBorder;
@property (weak, nonatomic) IBOutlet UILabel *labelHeaderMargin;
@property (weak, nonatomic) IBOutlet UILabel *labelHeaderSize;

@property (nonatomic, weak) IBOutlet UILabel *labelPaddingTop;
@property (nonatomic, weak) IBOutlet UILabel *labelPaddingBottom;
@property (nonatomic, weak) IBOutlet UILabel *labelPaddingLeft;
@property (nonatomic, weak) IBOutlet UILabel *labelPaddingRight;

@property (nonatomic, weak) IBOutlet UILabel *labelMarginTop;
@property (nonatomic, weak) IBOutlet UILabel *labelMarginBottom;
@property (nonatomic, weak) IBOutlet UILabel *labelMarginLeft;
@property (nonatomic, weak) IBOutlet UILabel *labelMarginRight;

@property (nonatomic, weak) IBOutlet UILabel *labelBorderTop;
@property (nonatomic, weak) IBOutlet UILabel *labelBorderBottom;
@property (nonatomic, weak) IBOutlet UILabel *labelBorderLeft;
@property (nonatomic, weak) IBOutlet UILabel *labelBorderRight;

@property (nonatomic, weak) IBOutlet UILabel *labelSizeWidth;
@property (nonatomic, weak) IBOutlet UILabel *labelSizeHeight;

@property (nonatomic, weak) IBOutlet UIButton *buttonBold;
@property (nonatomic, weak) IBOutlet UIButton *buttonItalic;
@property (nonatomic, weak) IBOutlet UIButton *buttonStrike;
@property (nonatomic, weak) IBOutlet UIButton *buttonUnderline;

@property (nonatomic, weak) IBOutlet UIStepper *stepperFontSize;

@property (nonatomic, weak) IBOutlet UIStepper *stepperBorderTop;
@property (nonatomic, weak) IBOutlet UIStepper *stepperBorderBottom;
@property (nonatomic, weak) IBOutlet UIStepper *stepperBorderLeft;
@property (nonatomic, weak) IBOutlet UIStepper *stepperBorderRight;

@property (nonatomic, weak) IBOutlet UIStepper *stepperPaddingTop;
@property (nonatomic, weak) IBOutlet UIStepper *stepperPaddingBottom;
@property (nonatomic, weak) IBOutlet UIStepper *stepperPaddingLeft;
@property (nonatomic, weak) IBOutlet UIStepper *stepperPaddingRight;

@property (nonatomic, weak) IBOutlet UIStepper *stepperMarginTop;
@property (nonatomic, weak) IBOutlet UIStepper *stepperMarginBottom;
@property (nonatomic, weak) IBOutlet UIStepper *stepperMarginLeft;
@property (nonatomic, weak) IBOutlet UIStepper *stepperMarginRight;

@property (nonatomic, weak) IBOutlet UIStepper *stepperSizeWidth;
@property (nonatomic, weak) IBOutlet UIStepper *stepperSizeHeight;

@property (nonatomic, weak) IBOutlet UISegmentedControl *segmentedControlHorizontalAlignment;

@property (nonatomic, weak) IBOutletCollection(UITableViewCell) NSArray *groupTableViewCellStyle;
@property (nonatomic, weak) IBOutletCollection(UITableViewCell) NSArray *groupTableViewCellLayout;

@property (nonatomic, weak) IBOutletCollection(UIStepper) NSArray *steppers;

@end

@implementation MADToolboxStyleViewController {
	BOOL _completedInitalLayout;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
	
	UISegmentedControl *segmentedControlHorizontalAlignment = _segmentedControlHorizontalAlignment;
	
	UIFont *font = [UIFont fontWithName:@"FontAwesome" size:12.0000f];;
	NSDictionary *attributes = [NSDictionary dictionaryWithObject:font
														   forKey:NSFontAttributeName];
	[segmentedControlHorizontalAlignment setTitleTextAttributes:attributes
													   forState:UIControlStateNormal];
	[segmentedControlHorizontalAlignment setTitle:@"\uf036" forSegmentAtIndex:0];
	[segmentedControlHorizontalAlignment setTitle:@"\uf037" forSegmentAtIndex:1];
	[segmentedControlHorizontalAlignment setTitle:@"\uf038" forSegmentAtIndex:2];
	[segmentedControlHorizontalAlignment setTitle:@"\uf039" forSegmentAtIndex:3];
	NSDictionary *attributesSelected = @{
		NSFontAttributeName : font,
		NSStrokeColorAttributeName : [UIColor whiteColor]
	};
	NSAttributedString *boldButton = [[NSAttributedString alloc] initWithString: @"\uf26c"
																	 attributes: attributes];
	NSAttributedString *boldButtonSelected = [[NSAttributedString alloc] initWithString: @"\uf26c"
																			 attributes: attributesSelected];
	self.tableView.delegate = self;
		
	self.buttonBold.layer.borderColor = self.view.tintColor.CGColor;
	self.buttonBold.layer.cornerRadius = CornerRadius;
	self.buttonBold.layer.borderWidth = BorderWidth;
	[self.buttonBold setTitle:@"\uf032" forState:UIControlStateNormal];
	[self.buttonBold setTitle:@"\uf032" forState:UIControlStateSelected];
	[self.buttonBold setTitle:@"\uf032" forState:UIControlStateHighlighted];
	[self.buttonBold setTitleColor:[MADColorEverydayApps newColorAnalogous4] forState:UIControlStateHighlighted];
	[self.buttonBold setTitleColor:self.view.tintColor forState:UIControlStateNormal];
	[self.buttonBold setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
	self.buttonBold.titleLabel.font = font;
	self.buttonBold.imageView.image = nil;
	
	self.buttonItalic.layer.borderColor = self.view.tintColor.CGColor;
	self.buttonItalic.layer.cornerRadius = CornerRadius;
	self.buttonItalic.layer.borderWidth = BorderWidth;
	[self.buttonItalic setTitle:@"\uf033" forState:UIControlStateNormal];
	[self.buttonItalic setTitle:@"\uf033" forState:UIControlStateSelected];
	[self.buttonItalic setTitle:@"\uf033" forState:UIControlStateHighlighted];
	[self.buttonItalic setTitleColor:[MADColorEverydayApps newColorAnalogous4] forState:UIControlStateHighlighted];
	[self.buttonItalic setTitleColor:self.view.tintColor forState:UIControlStateNormal];
	[self.buttonItalic setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
	self.buttonItalic.titleLabel.font = font;
	self.buttonItalic.imageView.image = nil;
	
	self.buttonStrike.layer.borderColor = self.view.tintColor.CGColor;
	self.buttonStrike.layer.cornerRadius = CornerRadius;
	self.buttonStrike.layer.borderWidth = BorderWidth;
	[self.buttonStrike setTitle:@"\uf0cc" forState:UIControlStateNormal];
	[self.buttonStrike setTitle:@"\uf0cc" forState:UIControlStateSelected];
	[self.buttonStrike setTitle:@"\uf0cc" forState:UIControlStateHighlighted];
	[self.buttonStrike setTitleColor:[MADColorEverydayApps newColorAnalogous4] forState:UIControlStateHighlighted];
	[self.buttonStrike setTitleColor:self.view.tintColor forState:UIControlStateNormal];
	[self.buttonStrike setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
	self.buttonStrike.titleLabel.font = font;
	self.buttonStrike.imageView.image = nil;
	
	self.buttonUnderline.layer.borderColor = self.view.tintColor.CGColor;
	self.buttonUnderline.layer.cornerRadius = CornerRadius;
	self.buttonUnderline.layer.borderWidth = BorderWidth;
	[self.buttonUnderline setTitle:@"\uf0cd" forState:UIControlStateNormal];
	[self.buttonUnderline setTitle:@"\uf0cd" forState:UIControlStateSelected];
	[self.buttonUnderline setTitle:@"\uf0cd" forState:UIControlStateHighlighted];
	[self.buttonUnderline setTitleColor:[MADColorEverydayApps newColorAnalogous4] forState:UIControlStateHighlighted];
	[self.buttonUnderline setTitleColor:self.view.tintColor forState:UIControlStateNormal];
	[self.buttonUnderline setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
	self.buttonUnderline.titleLabel.font = font;
	self.buttonUnderline.imageView.image = nil;
	
	self.labelFontName.textColor = [UIColor secondaryLabelColor];
	self.labelFontSize.textColor = [UIColor secondaryLabelColor];
	self.labelBorderTop.textColor = [UIColor secondaryLabelColor];
	self.labelMarginTop.textColor = [UIColor secondaryLabelColor];
	self.labelSizeWidth.textColor = [UIColor secondaryLabelColor];
	self.labelBorderLeft.textColor = [UIColor secondaryLabelColor];
	self.labelMarginLeft.textColor = [UIColor secondaryLabelColor];
	self.labelPaddingTop.textColor = [UIColor secondaryLabelColor];
	self.labelSizeHeight.textColor = [UIColor secondaryLabelColor];
	self.labelBorderRight.textColor = [UIColor secondaryLabelColor];
	self.labelMarginRight.textColor = [UIColor secondaryLabelColor];
	self.labelPaddingLeft.textColor = [UIColor secondaryLabelColor];
	self.labelBorderBottom.textColor = [UIColor secondaryLabelColor];
	self.labelMarginBottom.textColor = [UIColor secondaryLabelColor];
	self.labelPaddingRight.textColor = [UIColor secondaryLabelColor];
	self.labelPaddingBottom.textColor = [UIColor secondaryLabelColor];


	self.labelHeaderSize.textColor = [UIColor labelColor];
	self.labelHeaderBorder.textColor = [UIColor labelColor];
	self.labelHeaderMargin.textColor = [UIColor labelColor];
	self.labelHeaderPadding.textColor = [UIColor labelColor];

	self.fontLabelTableViewCell.textLabel.textColor = [UIColor labelColor];

	_completedInitalLayout = NO;
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	UIEdgeInsets safeAreaInsets;
	MADViewSafeAreaInserts(self.view, &safeAreaInsets);
	self.tableView.contentInset = UIEdgeInsetsMake(safeAreaInsets.top, CGSizeZero.width, safeAreaInsets.bottom, CGSizeZero.width);
	self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(safeAreaInsets.top, CGSizeZero.width, safeAreaInsets.bottom, CGSizeZero.width);
	if (_completedInitalLayout == NO) {
		[self.tableView setContentOffset: CGPointMake(CGPointZero.x, -safeAreaInsets.top) animated: NO];
		_completedInitalLayout = YES;
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self updateDisplay];
	self.view.backgroundColor = [UIColor clearColor];
	self.view.opaque = NO;
	self.tableView.backgroundColor = [UIColor clearColor];
	self.tableView.opaque = NO;
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	if (self.clearsBackground) {
		self.tableView.backgroundView = nil;
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

#pragma mark -
#pragma mark Actions

- (void)setStateInControl:(UIControl *)control forState:(MTControlState)state {
	
	
	BOOL select, highlight;
	UIColor *backgroundColor, *titleColor;
	
	switch (state) {
		case MTControlStateOn:
			select = YES;
			highlight = YES;
			backgroundColor = self.view.tintColor;
			titleColor = [UIColor whiteColor];
			break;
		case MTControlStateOff:
			select = NO;
			highlight = NO;
			backgroundColor = [UIColor clearColor];
			titleColor = self.view.tintColor;
			break;
		case MTControlStateAmbiguous:
			select = YES;
			highlight = NO;
			backgroundColor = [self.view.tintColor colorWithAlphaComponent:0.5000f];
			titleColor = [UIColor whiteColor];
			break;
		default:
			select = NO;
			highlight = NO;
			backgroundColor = [UIColor clearColor];
			titleColor = self.view.tintColor;
			break;
	}
	
	control.highlighted = highlight;
	control.selected = select;
	
	if ([control isKindOfClass:[UIButton class]]) {
		control.backgroundColor = backgroundColor;
		[((UIButton *)control) setTitleColor:titleColor forState:control.state];
	}
}

- (void)setSelectedDocumentObjects:(NSSet <NSNumber *> *)objectIds {
	self.userSelectedObjectIDs = objectIds;
	[self updateDisplay];
}

- (void)updateDisplay {

	if (!self.isViewLoaded) return;
	
	UISegmentedControl *segmentedControlHorizontalAlignment;
	segmentedControlHorizontalAlignment = _segmentedControlHorizontalAlignment;
	
	void(^updateControlsEnabled)(BOOL) = ^void(BOOL enabled) {
		
		self.buttonItalic.      enabled = enabled;
		self.buttonBold.        enabled = enabled;
		self.buttonStrike.      enabled = enabled;
		self.buttonUnderline.   enabled = enabled;
		self.buttonBold.selected = enabled;
		//self.buttonBold.highlighted = enabled;
		
		self.buttonItalic.selected = enabled;
		//self.buttonItalic.highlighted = enabled;
		
		self.buttonStrike.selected = enabled;
		//self.buttonStrike.highlighted = enabled;
		
		self.buttonUnderline.selected = enabled;
		//self.buttonUnderline.highlighted = enabled;
		
		segmentedControlHorizontalAlignment.selected = NO;
		segmentedControlHorizontalAlignment.highlighted = NO;
		
		segmentedControlHorizontalAlignment.selectedSegmentIndex =
		!enabled ? UISegmentedControlNoSegment :
		segmentedControlHorizontalAlignment.selectedSegmentIndex;
		segmentedControlHorizontalAlignment.userInteractionEnabled = NO;
		
		self.fontLabelTableViewCell.userInteractionEnabled = NO;
		self.stepperFontSize.userInteractionEnabled = NO;
		
	};
	
	if (self.userSelectedObjectIDs.count == 0) {
		updateControlsEnabled(NO);
		
		self.controlStateBold = MTControlStateOff;
		self.controlStateItalic = MTControlStateOff;
		self.controlStateStrike = MTControlStateOff;
		self.controlStateUnderline = MTControlStateOff;
		
		self.labelFontName.attributedText = [MADToolboxStrings boldSystemString: NSLocalizedString(@"Nothing Selected", @"Nothing Selected")];
		self.labelFontSize.attributedText = [MADToolboxStrings boldSystemString: NSLocalizedString(@"Nothing", @"Nothing")];

		NSArray *steppers = self.steppers;
		for (UIStepper *stepper in steppers) {
			stepper.userInteractionEnabled = NO;
		}

		self.labelSizeHeight.attributedText = [MADToolboxStrings sizeHeightForValue:0];
		self.labelSizeWidth.attributedText = [MADToolboxStrings sizeWidthForValue:0];
		
		self.labelBorderTop.attributedText = [MADToolboxStrings marginTopForValue:0];
		self.labelBorderBottom.attributedText = [MADToolboxStrings marginBottomForValue:0];
		self.labelBorderLeft.attributedText = [MADToolboxStrings marginLeftForValue:0];
		self.labelBorderRight.attributedText = [MADToolboxStrings marginRightForValue:0];
		
		self.labelMarginTop.attributedText = [MADToolboxStrings marginTopForValue:0];
		self.labelMarginBottom.attributedText = [MADToolboxStrings marginBottomForValue:0];
		self.labelMarginLeft.attributedText = [MADToolboxStrings marginLeftForValue:0];
		self.labelMarginRight.attributedText = [MADToolboxStrings marginRightForValue:0];
		
		self.labelPaddingTop.attributedText = [MADToolboxStrings marginTopForValue:0];
		self.labelPaddingBottom.attributedText = [MADToolboxStrings marginBottomForValue:0];
		self.labelPaddingLeft.attributedText = [MADToolboxStrings marginLeftForValue:0];
		self.labelPaddingRight.attributedText = [MADToolboxStrings marginRightForValue:0];

	} else {
		updateControlsEnabled(YES);
		
		NSArray *steppers = self.steppers;
		for (UIStepper *stepper in steppers) {
			[stepper setUserInteractionEnabled:YES];
		}
		
		self.controlStateBold = MTControlStateOn;
		self.controlStateItalic = MTControlStateOn;
		self.controlStateStrike = MTControlStateOn;
		self.controlStateUnderline = MTControlStateOn;
		
		NSString *fontDisplayName = nil;
		
		MADMargin *marginHolder = [[MADMargin alloc] init];
		MADPadding *paddingHolder = [[MADPadding alloc] init];
		MADBorderStyle *borderHolder = [[MADBorderStyle alloc] init];
		
		MADAlignment_t alignmentHolder = MADAlignmentMake(MADHorizontalAlignmentUnknown, MADVerticalAlignmentUnknown);
		CGSize sizeHolder = CGSizeZero;
		
		CGFloat fontSizeHolder = (CGFloat)[MADFont defaultSize];
		
		NSInteger numberOfMarginTop             = 0,
		numberOfMarginBottom          = 0,
		numberOfMarginLeft            = 0,
		numberOfMarginRight           = 0,
		numberOfPaddingTop            = 0,
		numberOfPaddingBottom         = 0,
		numberOfPaddingLeft           = 0,
		numberOfPaddingRight          = 0,
		numberOfBorderTop             = 0,
		numberOfBorderBottom          = 0,
		numberOfBorderLeft            = 0,
		numberOfBorderRight           = 0,
		numberOfHorazontalAlignments  = 0,
		numberOfVerticalAlignments    = 0,
		numberOfSizeWidths            = 0,
		numberOfSizeHeights           = 0,
		numberFonts                   = 0,
		numberBold                    = 0,
		numberItalic                  = 0,
		numberStrike                  = 0,
		numberUnderline               = 0,
		numberNotBold                 = 0,
		numberNotItalic               = 0,
		numberNotStrike               = 0,
		numberNotUnderline            = 0;
		
		NSNumber *objectId;
		NSSet <NSNumber *> *userSelectedObjectIDs = _userSelectedObjectIDs;
		RptqDocumentElement *documentObject;
		
		CGSize size;
		NSManagedObjectContext *context = self.document.managedObjectContext;
		for (objectId in userSelectedObjectIDs) {
			
			documentObject = [RptqDocumentElement newDocumentElementWithIdentifier:objectId.longLongValue
																 fromObjectContext:context];
			
			if (documentObject != nil) {
				
				if ((fontDisplayName == nil && documentObject.fontname != nil) ||
					(fontDisplayName != nil &&
					 ![documentObject.fontname isEqualToString:fontDisplayName])) {
					
					fontDisplayName = documentObject.fontname;
					fontSizeHolder = documentObject.fontsize;
					numberFonts++;
				}
				
				size = CGSizeMake(documentObject.rect.size.width, documentObject.rect.size.height);
				//[(NSValue *)documentObject.size getValue:&size];
				
				if (documentObject.border.width.top != borderHolder.top ) {
					borderHolder.top = documentObject.border.width.top;
					numberOfBorderTop++;
				}
				if (documentObject.border.width.bottom != borderHolder.bottom ) {
					borderHolder.bottom = documentObject.border.width.bottom;
					numberOfBorderBottom++;
				}
				if (documentObject.border.width.left != borderHolder.left ) {
					borderHolder.left = documentObject.border.width.left;
					numberOfBorderLeft++;
				}
				if (documentObject.border.width.right != borderHolder.right ) {
					borderHolder.right = documentObject.border.width.right;
					numberOfBorderRight++;
				}
				
				if (documentObject.margin.top != marginHolder.top ) {
					marginHolder.top = documentObject.margin.top;
					numberOfMarginTop++;
				}
				
				if (documentObject.margin.bottom != marginHolder.bottom ) {
					marginHolder.bottom = documentObject.margin.bottom;
					numberOfMarginBottom++;
				}
				
				if (documentObject.margin.left != marginHolder.left ) {
					marginHolder.left = documentObject.margin.left;
					numberOfMarginLeft++;
				}
				
				if (documentObject.margin.right != marginHolder.right ) {
					marginHolder.right = documentObject.margin.right;
					numberOfMarginRight++;
				}
				
				if (documentObject.padding.top != paddingHolder.top ) {
					paddingHolder.top = documentObject.padding.top;
					numberOfPaddingTop++;
				}
				
				if (documentObject.padding.bottom != paddingHolder.bottom ) {
					paddingHolder.bottom = documentObject.padding.bottom;
					numberOfPaddingBottom++;
				}
				
				if (documentObject.padding.left != paddingHolder.left ) {
					paddingHolder.left = documentObject.padding.left;
					numberOfPaddingLeft++;
				}
				
				if (documentObject.padding.right != paddingHolder.right ) {
					paddingHolder.right = documentObject.padding.right;
					numberOfPaddingRight++;
				}
				
				if (documentObject.rect.size.width != sizeHolder.width ) {
					sizeHolder.width = size.width;
					numberOfSizeWidths++;
				}
				
				if (documentObject.rect.size.height != sizeHolder.height ) {
					sizeHolder.height = size.height;
					numberOfSizeHeights++;
				}
				
				if (documentObject.alignment.vertical != alignmentHolder.vertical) {
					alignmentHolder.vertical = documentObject.alignment.vertical;
					numberOfVerticalAlignments++;
				}
				if (documentObject.alignment.horizontal != alignmentHolder.horizontal) {
					alignmentHolder.horizontal = documentObject.alignment.horizontal;
					numberOfHorazontalAlignments++;
				}
				
				documentObject.textStyle.bold ? numberBold++ : numberNotBold++;
				documentObject.textStyle.underline ? numberUnderline++ : numberNotUnderline++;
				documentObject.textStyle.strikethrough ? numberStrike++ : numberNotStrike++;
				documentObject.textStyle.italic ? numberItalic++ : numberNotItalic++;
				
			}
			
		}
		
		segmentedControlHorizontalAlignment.selectedSegmentIndex = documentObject.alignment.horizontal;
		
		double displayNumber = numberOfMarginTop >= 1 ? marginHolder.top : 0;
		_labelMarginTop.attributedText = [MADToolboxStrings marginTopForValue:displayNumber];
		_stepperMarginTop.value = marginHolder.top;
		
		displayNumber = numberOfMarginBottom == 1 ? marginHolder.bottom : 0;
		_labelMarginBottom.attributedText = [MADToolboxStrings marginBottomForValue:displayNumber];
		_stepperMarginBottom.value = marginHolder.bottom;
		
		displayNumber = numberOfMarginLeft == 1 ? marginHolder.left : 0;
		_labelMarginLeft.attributedText = [MADToolboxStrings marginLeftForValue:displayNumber];
		_stepperMarginLeft.value = marginHolder.left;
		
		displayNumber = numberOfMarginRight == 1 ? marginHolder.right : 0;
		_labelMarginRight.attributedText = [MADToolboxStrings marginRightForValue:displayNumber];
		_stepperMarginRight.value = marginHolder.right;
		
		displayNumber = numberOfPaddingTop == 1 ? paddingHolder.top : 0;
		_labelPaddingTop.attributedText = [MADToolboxStrings marginTopForValue:displayNumber];
		_stepperPaddingTop.value = paddingHolder.top;
		
		displayNumber = numberOfPaddingBottom == 1 ? paddingHolder.bottom : 0;
		_labelPaddingBottom.attributedText = [MADToolboxStrings marginBottomForValue:displayNumber];
		_stepperPaddingBottom.value = paddingHolder.bottom;
		
		displayNumber = numberOfPaddingLeft == 1 ? paddingHolder.left : 0;
		_labelPaddingLeft.attributedText = [MADToolboxStrings marginLeftForValue:displayNumber];
		_stepperPaddingLeft.value = paddingHolder.left;
		
		displayNumber = numberOfPaddingRight == 1 ? paddingHolder.right : 0;
		_labelPaddingRight.attributedText = [MADToolboxStrings marginRightForValue:displayNumber];
		_stepperPaddingRight.value = paddingHolder.right;
		
		displayNumber = numberOfBorderTop == 1 ? borderHolder.top : 0;
		_labelBorderTop.attributedText = [MADToolboxStrings marginTopForValue:displayNumber];
		_stepperBorderTop.value = borderHolder.top;
		
		displayNumber = numberOfBorderBottom == 1 ? borderHolder.bottom : 0;
		_labelBorderBottom.attributedText = [MADToolboxStrings marginBottomForValue:displayNumber];
		_stepperBorderBottom.value = borderHolder.bottom;
		
		displayNumber = numberOfBorderLeft == 1 ? borderHolder.left : 0;
		_labelBorderLeft.attributedText = [MADToolboxStrings marginLeftForValue:displayNumber];
		_stepperBorderLeft.value = borderHolder.left;
		
		displayNumber = numberOfBorderRight == 1 ? borderHolder.right : 0;
		_labelBorderRight.attributedText = [MADToolboxStrings marginRightForValue:displayNumber];
		_stepperBorderRight.value = borderHolder.right;
		
		displayNumber = numberOfSizeHeights == 1 ? sizeHolder.height : 0;
		_labelSizeHeight.attributedText = [MADToolboxStrings sizeHeightForValue:displayNumber];
		_stepperSizeHeight.value = size.height;
		
		displayNumber = numberOfSizeWidths == 1 ? sizeHolder.width : 0;
		_labelSizeWidth.attributedText = [MADToolboxStrings sizeWidthForValue:displayNumber];
		_stepperSizeWidth.value = size.width;
		
		UILabel *labelFontName = _labelFontName, *labelFontSize = _labelFontSize;
		NSAttributedString *display;
		switch (numberFonts) {
			case 0: {
				fontDisplayName = NSLocalizedString(@"Undefined", @"Undefined");
				display = [MADToolboxStrings boldSystemString:fontDisplayName];
				labelFontName.attributedText = display;
				break;
			}
			case 1: {
				display = [MADToolboxStrings boldSystemString:fontDisplayName];
				labelFontName.attributedText = display;
				display = [MADToolboxStrings attributedStringFontSizeInPoints: fontSizeHolder
																 withFontSize: labelFontSize.font.pointSize];
				labelFontSize.attributedText = display;
				break;
			}
			default: {
				fontDisplayName = NSLocalizedString(@"Ambiguous", @"Ambiguous");
				display = [MADToolboxStrings boldSystemString:fontDisplayName];
				labelFontName.attributedText = display;
				display = [MADToolboxStrings boldSystemString:fontDisplayName];
				labelFontSize.attributedText = display;
				break;
			}
		}
		
		UIStepper *stepperFontSize = _stepperFontSize;
		stepperFontSize.value = fontSizeHolder;
		
		_controlStateBold = numberBold > 0 ? ( numberNotBold > 0 ? MTControlStateAmbiguous : MTControlStateOn) : MTControlStateOff;
		_controlStateItalic = numberItalic > 0 ? ( numberNotItalic > 0 ? MTControlStateAmbiguous : MTControlStateOn) : MTControlStateOff;
		_controlStateStrike = numberStrike > 0 ? ( numberNotStrike > 0 ? MTControlStateAmbiguous : MTControlStateOn) : MTControlStateOff;
		_controlStateUnderline = numberUnderline > 0 ? ( numberNotUnderline > 0 ? MTControlStateAmbiguous : MTControlStateOn) : MTControlStateOff;
		
		MTControlState controlStateHorizontalAlignment = numberOfHorazontalAlignments > 0 ?
		(numberOfHorazontalAlignments == 1 ? MTControlStateOn : MTControlStateAmbiguous) :
		MTControlStateOff;
		[self setStateInControl:segmentedControlHorizontalAlignment forState:controlStateHorizontalAlignment];
		
		_fontLabelTableViewCell.userInteractionEnabled = YES;
		stepperFontSize.userInteractionEnabled = YES;
		segmentedControlHorizontalAlignment.userInteractionEnabled = YES;
		
	}
	[self setStateInControl: _buttonBold        forState: _controlStateBold];
	[self setStateInControl: _buttonItalic      forState: _controlStateItalic];
	[self setStateInControl: _buttonStrike      forState: _controlStateStrike];
	[self setStateInControl: _buttonUnderline   forState: _controlStateUnderline];
}

- (void)emptySelector:(id)whofuckingCares { }

#pragma mark -
#pragma mark Control Event Handlers

#pragma mark Text Style

- (void)chooseFamilyName:(NSString *)familyName {
	CGFloat systemFontSize = [UIFont systemFontSize];
	UIFont *font = [UIFont fontWithName:familyName size:systemFontSize];
	
	UILabel *labelFontName = _labelFontName;
	
	labelFontName.font = font;
	labelFontName.text = familyName.copy;
	
	[self.document.designerLayout updateElements:self.userSelectedObjectIDs setFontname:familyName];
}

- (IBAction)handleFontSizeChanged:(UIStepper *)sender {
	UILabel *labelFontSize = _labelFontSize;
	NSAttributedString *attributedString;
	attributedString = [MADToolboxStrings attributedStringFontSizeInPoints: sender.value
															  withFontSize: labelFontSize.font.pointSize];
	labelFontSize.attributedText = attributedString;
	[self.document.designerLayout updateElements:self.userSelectedObjectIDs setFontsize:sender.value];
}

- (IBAction)handleHorizontalAlignmentChanged:(UISegmentedControl *)sender {
	[self.segmentedControlHorizontalAlignment setBackgroundImage: nil
														forState: UIControlStateNormal
													  barMetrics: UIBarMetricsDefault];
	[self.document.designerLayout updateElements:self.userSelectedObjectIDs
						  setHorizontalAlignment:(int16_t)sender.selectedSegmentIndex];
}

- (IBAction)toggleBold:(id)sender {
	
	switch (self.controlStateBold) {
		case MTControlStateOn:
			self.controlStateBold = MTControlStateOff;
			break;
		case MTControlStateOff:
		case MTControlStateAmbiguous:
		default:
			self.controlStateBold = MTControlStateOn;
			break;
	}
	[self setStateInControl:self.buttonBold forState:self.controlStateBold];
	
	MADocument *document = self.document;
	[document.designerLayout updateElements:self.userSelectedObjectIDs
									setBold:ControlStateIsOn(self.controlStateBold)];
}

- (IBAction)toggleItalic:(id)sender {
	switch (self.controlStateItalic) {
		case MTControlStateOn:
			self.controlStateItalic = MTControlStateOff;
			break;
		case MTControlStateOff:
		case MTControlStateAmbiguous:
		default:
			self.controlStateItalic = MTControlStateOn;
			break;
	}
	[self setStateInControl:self.buttonItalic forState:self.controlStateItalic];
	
	MADocument *document = self.document;
	[document.designerLayout updateElements:self.userSelectedObjectIDs
								  setItalic:ControlStateIsOn(self.controlStateItalic)];
}

- (IBAction)toggleStrikeThrough:(id)sender {
	switch (self.controlStateStrike) {
		case MTControlStateOn:
			self.controlStateStrike = MTControlStateOff;
			break;
		case MTControlStateOff:
			self.controlStateStrike = MTControlStateOn;
			break;
		case MTControlStateAmbiguous:
			self.controlStateStrike = MTControlStateOn;
			break;
		default:
			self.controlStateStrike = MTControlStateOn;
			break;
	}
	[self setStateInControl:self.buttonStrike forState:self.controlStateStrike];
	
	MADocument *document = self.document;
	[document.designerLayout updateElements:self.userSelectedObjectIDs
						   setStrikethrough:ControlStateIsOn(self.controlStateStrike)];
}

- (IBAction)toggleUnderline:(id)sender {
	switch (self.controlStateUnderline) {
		case MTControlStateOn:
			self.controlStateUnderline = MTControlStateOff;
			break;
		case MTControlStateOff:
			self.controlStateUnderline = MTControlStateOn;
			break;
		case MTControlStateAmbiguous:
			self.controlStateUnderline = MTControlStateOn;
			break;
		default:
			self.controlStateUnderline = MTControlStateOn;
			break;
	}
	[self setStateInControl:self.buttonUnderline forState:self.controlStateUnderline];
	
	[self.document.designerLayout updateElements:self.userSelectedObjectIDs
									setUnderline:ControlStateIsOn(self.controlStateUnderline)];
}

#pragma mark Content Size

- (IBAction)handleContentWidthChanged:(id)sender {
	self.labelSizeWidth.attributedText = [MADToolboxStrings sizeWidthForValue:((UIStepper *)sender).value];;
	[self.document.designerLayout updateElements:self.userSelectedObjectIDs
									setSizeWidth:(float)((UIStepper *)sender).value];
}

- (IBAction)handleContentHeightChanged:(id)sender {
	self.labelSizeHeight.attributedText = [MADToolboxStrings sizeHeightForValue:((UIStepper *)sender).value];
	[self.document.designerLayout updateElements:self.userSelectedObjectIDs
								   setSizeHeight:(float)((UIStepper *)sender).value];
}

#pragma mark Margin

- (IBAction)handleMarginTopChanged:(id)sender {
	self.labelMarginTop.attributedText = [MADToolboxStrings marginTopForValue: ((UIStepper *)sender).value];;
	[self.document.designerLayout updateElements:self.userSelectedObjectIDs
									setMarginTop:(float)((UIStepper *)sender).value];
}

- (IBAction)handleMarginBottomChanged:(id)sender {
	self.labelMarginBottom.attributedText = [MADToolboxStrings marginBottomForValue:((UIStepper *)sender).value];
	[self.document.designerLayout updateElements:self.userSelectedObjectIDs
								 setMarginBottom:(float)((UIStepper *)sender).value];
}

- (IBAction)handleMarginLeftChanged:(id)sender {
	self.labelMarginLeft.attributedText = [MADToolboxStrings marginLeftForValue: ((UIStepper *)sender).value];
	[self.document.designerLayout updateElements:self.userSelectedObjectIDs
								   setMarginLeft:(float)((UIStepper *)sender).value];
}

- (IBAction)handleMarginRightChanged:(id)sender {
	self.labelMarginRight.attributedText = [MADToolboxStrings marginRightForValue: ((UIStepper *)sender).value];
	[self.document.designerLayout updateElements:self.userSelectedObjectIDs
								  setMarginRight:(float)((UIStepper *)sender).value];
}

#pragma mark Padding

- (IBAction)handlePaddingTopChanged:(id)sender {
	self.labelPaddingTop.attributedText = [MADToolboxStrings marginTopForValue: ((UIStepper *)sender).value];
	[self.document.designerLayout updateElements:self.userSelectedObjectIDs
								   setPaddingTop:(float)((UIStepper *)sender).value];
}

- (IBAction)handlePaddingBottomChanged:(id)sender {
	self.labelPaddingBottom.attributedText = [MADToolboxStrings marginBottomForValue:((UIStepper *)sender).value];
	[self.document.designerLayout updateElements:self.userSelectedObjectIDs
								setPaddingBottom:(float)((UIStepper *)sender).value];
}

- (IBAction)handlePaddingLeftChanged:(id)sender {
	self.labelPaddingLeft.attributedText = [MADToolboxStrings marginLeftForValue: ((UIStepper *)sender).value];
	[self.document.designerLayout updateElements:self.userSelectedObjectIDs
								  setPaddingLeft:(float)((UIStepper *)sender).value];
}

- (IBAction)handlePaddingRightChanged:(id)sender {
	self.labelPaddingRight.attributedText = [MADToolboxStrings marginRightForValue: ((UIStepper *)sender).value];
	[self.document.designerLayout updateElements:self.userSelectedObjectIDs
								 setPaddingRight:(float)((UIStepper *)sender).value];
}

#pragma mark Border

- (IBAction)handleBorderTopChanged:(id)sender {
	self.labelBorderTop.attributedText = [MADToolboxStrings marginTopForValue: ((UIStepper *)sender).value];
	[self.document.designerLayout updateElements:self.userSelectedObjectIDs
									setBorderTop:(float)((UIStepper *)sender).value];
}

- (IBAction)handleBorderBottomChanged:(id)sender {
	self.labelBorderBottom.attributedText = [MADToolboxStrings marginBottomForValue:((UIStepper *)sender).value];
	[self.document.designerLayout updateElements:self.userSelectedObjectIDs
								 setBorderBottom:(float)((UIStepper *)sender).value];
}

- (IBAction)handleBorderLeftChanged:(id)sender {
	self.labelBorderLeft.attributedText = [MADToolboxStrings marginLeftForValue: ((UIStepper *)sender).value];
	[self.document.designerLayout updateElements:self.userSelectedObjectIDs
								   setBorderLeft:(float)((UIStepper *)sender).value];
}

- (IBAction)handleBorderRightChanged:(id)sender {
	self.labelBorderRight.attributedText = [MADToolboxStrings marginRightForValue: ((UIStepper *)sender).value];
	[self.document.designerLayout updateElements:self.userSelectedObjectIDs
								  setBorderRight:(float)((UIStepper *)sender).value];
}

#pragma mark -
#pragma mark MADReportDesignerFontSelectorDelegateProtocol

- (void)tableViewControllerDidUpdateFontToFontWithName:(NSString *)fontName {
	[self chooseFamilyName:fontName];
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	cell.backgroundColor = [UIColor clearColor];
	cell.contentView.backgroundColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath { }

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath { }

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath { }

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark UIViewController

- (IBSegueAction MADFontSelectorViewController *)segueFontController:(NSCoder *)coder {
	MADFontSelectorViewController *result = [[MADFontSelectorViewController alloc] initWithCoder:coder];
	result.fontSelectorDelegate = self;
	return result;
}


- (void)prepareForSegues:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:MADIdentifierStoryboardSeguePushFontPicker]) {
		MADFontSelectorViewController *destination = segue.destinationViewController;
		destination.fontSelectorDelegate = self;
		destination.clearsBackground = self.clearsBackground;
		NSNumber *identifier = [self.userSelectedObjectIDs anyObject];
		RptqDocumentElement *element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
																		   fromObjectContext:_document.managedObjectContext];
		[destination setFamilyName:element.fontname];
	}
}

@end

@implementation MADToolboxStrings

+ (NSAttributedString *)systemString:(NSString *)string {
	UIFont *font = [UIFont systemFontOfSize:UIFont.labelFontSize];
	NSDictionary *attributes = @{NSFontAttributeName: font};
	return [[NSAttributedString alloc] initWithString:string ?: @"" attributes:attributes];
}

+ (NSAttributedString *)boldSystemString:(NSString *)string {
	UIFont *boldFont = [UIFont boldSystemFontOfSize:UIFont.labelFontSize];
	NSDictionary *attributes = @{NSFontAttributeName: boldFont};
	return [[NSAttributedString alloc] initWithString:string ?: @"" attributes:attributes];
}

+ (NSAttributedString *)stringForSubject:(NSString *)subject value:(NSString *)value {
	NSAttributedString *boldSubject = [self boldSystemString:subject];
	NSAttributedString *normalValue = [self systemString:[@" " stringByAppendingString:value]];
	
	NSMutableAttributedString *result = [boldSubject mutableCopy];
	[result appendAttributedString:normalValue];
	return result;
}

+ (NSAttributedString *)sizeWidthForValue:(double)value {
	NSString *stringValue = value <= 0 ? @"--" : [NSString stringWithFormat:NSLocalizedString(@"%#.1f pt", @"Like '5.2 points.'"), value];
	return [self stringForSubject:NSLocalizedString(@"Width", @"Width") value:stringValue];
}

+ (NSAttributedString *)sizeHeightForValue:(double)value {
	NSString *stringValue = value <= 0 ? @"--" : [NSString stringWithFormat:NSLocalizedString(@"%#.1f pt", @"Like '5.2 points.'"), value];
	return [self stringForSubject:NSLocalizedString(@"Height", @"Height") value:stringValue];
}

+ (NSAttributedString *)marginTopForValue:(double)value {
	NSString *stringValue = value <= 0 ? @"--" : [NSString stringWithFormat:NSLocalizedString(@"%#.1f pt", @"Like '5.2 points.'"), value];
	return [self stringForSubject:NSLocalizedString(@"Top", @"Top") value:stringValue];
}

+ (NSAttributedString *)marginBottomForValue:(double)value {
	NSString *stringValue = value <= 0 ? @"--" : [NSString stringWithFormat:NSLocalizedString(@"%#.1f pt", @"Like '5.2 points.'"), value];
	return [self stringForSubject:NSLocalizedString(@"Bottom", @"Bottom") value:stringValue];
}

+ (NSAttributedString *)marginLeftForValue:(double)value {
	NSString *stringValue = value <= 0 ? @"--" : [NSString stringWithFormat:NSLocalizedString(@"%#.1f pt", @"Like '5.2 points.'"), value];
	return [self stringForSubject:NSLocalizedString(@"Left", @"Left") value:stringValue];
}

+ (NSAttributedString *)marginRightForValue:(double)value {
	NSString *stringValue = value <= 0 ? @"--" : [NSString stringWithFormat:NSLocalizedString(@"%#.1f pt", @"Like '5.2 points.'"), value];
	return [self stringForSubject:NSLocalizedString(@"Right", @"Right") value:stringValue];
}

+ (NSAttributedString *)attributedStringFontSizeInPoints:(double)pointsDisplay
											withFontSize:(CGFloat)pointSize {
	UIFont *boldFont = [UIFont boldSystemFontOfSize:pointSize];
	UIFont *systemFont = [UIFont systemFontOfSize:pointSize];
	
	NSMutableAttributedString *message = [[NSMutableAttributedString alloc]
										  initWithString:NSLocalizedString(@"Font size", @"Font size")
										  attributes:@{NSFontAttributeName: boldFont}];
	
	NSString *suffixText = [NSString stringWithFormat:@" %#.1f pt", pointsDisplay];
	NSAttributedString *suffix = [[NSAttributedString alloc]
								  initWithString:suffixText
								  attributes:@{NSFontAttributeName: systemFont}];
	
	[message appendAttributedString:suffix];
	return message;
}

@end
