//
//  fontSettingsTableViewController.m
//  Reports
//
//  Created by Michael Thomason on 1/5/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADToolboxStyleViewController.h"
#import <asl.h>
#import <QuartzCore/CALayer.h>

#import <CoreData/NSManagedObjectContext.h>

#import <UIKit/NSAttributedString.h>
#import <UIKit/UIStepper.h>
#import <UIKit/UISegmentedControl.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIButton.h>
#import <UIKit/UIImageView.h>
#import <UIKit/UIStoryboardSegue.h>

#import <MADCocoaExtensions/MADBorderStyle.h>
#import <MADCocoaExtensions/MADMargin.h>
#import <MADCocoaExtensions/MADPadding.h>
#import <MADCocoaExtensions/MADTextStyle.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

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

#import "MADControlState.h"

#import "MADReportDesignerFontSelectorDelegateProtocol.h"
#import "MADDesignerDisplayProtocol.h"

static const CGFloat CornerRadius = 6.6666f;
static const CGFloat BorderWidth = 1.0000f;

static NSString * const MADIdentifierStoryboardSeguePushFontPicker = @"MADIdentifierStoryboardSeguePushFontPicker";

static inline BOOL ControlStateIsOn(MTControlState controlState);
static inline BOOL ControlStateIsOn(MTControlState controlState) {
    return controlState == MTControlStateOn;
}

@interface MADToolboxStrings : NSAttributedString

    + (instancetype)newSystemString:(NSString *)string;
    + (instancetype)newBoldSystemString:(NSString *)string;
    + (instancetype)newStringForSubject:(NSString *)subject value:(NSString *)value;
    + (instancetype)newSizeWidthForValue:(double)value;
    + (instancetype)newSizeHeightForValue:(double)value;
    + (instancetype)newMarginTopForValue:(double)value;
    + (instancetype)newMarginBottomForValue:(double)value;
    + (instancetype)newMarginLeftForValue:(double)value;
    + (instancetype)newMarginRightForValue:(double)value;
    + (instancetype)newAttributedStringFontSizeInPoints:(double)pointsDisplay
                                           withFontSize:(CGFloat)pointSize;

@end

@interface MADToolboxStyleViewController()
    <UITableViewDelegate>

    @property (nonatomic, assign) MTControlState controlStateBold;
    @property (nonatomic, assign) MTControlState controlStateItalic;
    @property (nonatomic, assign) MTControlState controlStateStrike;
    @property (nonatomic, assign) MTControlState controlStateUnderline;

    @property (nonatomic, strong) NSSet <NSNumber *> *userSelectedObjectIDs;

    @property (nonatomic, weak) IBOutlet UITableViewCell *fontLabelTableViewCell;
    @property (nonatomic, weak) IBOutlet UILabel *labelFontSize;

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
    
    UISegmentedControl *segmentedControlHorizontalAlignment;
    segmentedControlHorizontalAlignment = _segmentedControlHorizontalAlignment;

    UIFont *font = [UIFont fontWithName:@"FontAwesome" size:12.0000f];;
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:font
                                                           forKey:NSFontAttributeName];
    [segmentedControlHorizontalAlignment setTitleTextAttributes:attributes
                                                       forState:UIControlStateNormal];
    [segmentedControlHorizontalAlignment setTitle:@"\uf036" forSegmentAtIndex:0];
    [segmentedControlHorizontalAlignment setTitle:@"\uf037" forSegmentAtIndex:1];
    [segmentedControlHorizontalAlignment setTitle:@"\uf038" forSegmentAtIndex:2];
    [segmentedControlHorizontalAlignment setTitle:@"\uf039" forSegmentAtIndex:3];
    UIColor *w = [UIColor whiteColor];
    NSDictionary *attributesSelected = @{
                                         NSFontAttributeName : font,
                                         NSStrokeColorAttributeName : w
                                         };
    NSAttributedString *boldButton, *boldButtonSelected;
    boldButton = [[NSAttributedString alloc] initWithString: @"\uf26c"
                                                 attributes: attributes];
    boldButtonSelected = [[NSAttributedString alloc] initWithString: @"\uf26c"
                                                         attributes: attributesSelected];
    self.tableView.delegate = self;
    UIColor *redColor = [MADColorEverydayApps newColorAnalogous4];
    self.buttonBold.layer.borderColor = self.view.tintColor.CGColor;
    self.buttonBold.layer.cornerRadius = CornerRadius;
    self.buttonBold.layer.borderWidth = BorderWidth;
    [self.buttonBold setTitle:@"\uf032" forState:UIControlStateNormal];
    [self.buttonBold setTitle:@"\uf032" forState:UIControlStateSelected];
    [self.buttonBold setTitle:@"\uf032" forState:UIControlStateHighlighted];
    [self.buttonBold setTitleColor:redColor forState:UIControlStateHighlighted];
    [self.buttonBold setTitleColor:self.view.tintColor forState:UIControlStateNormal];
    [self.buttonBold setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    self.buttonBold.titleLabel.font = font;
    self.buttonBold.imageView.image = nil;
    
    redColor = [MADColorEverydayApps newColorAnalogous4];
    self.buttonItalic.layer.borderColor = self.view.tintColor.CGColor;
    self.buttonItalic.layer.cornerRadius = CornerRadius;
    self.buttonItalic.layer.borderWidth = BorderWidth;
    [self.buttonItalic setTitle:@"\uf033" forState:UIControlStateNormal];
    [self.buttonItalic setTitle:@"\uf033" forState:UIControlStateSelected];
    [self.buttonItalic setTitle:@"\uf033" forState:UIControlStateHighlighted];
    [self.buttonItalic setTitleColor:redColor forState:UIControlStateHighlighted];
    [self.buttonItalic setTitleColor:self.view.tintColor forState:UIControlStateNormal];
    [self.buttonItalic setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    self.buttonItalic.titleLabel.font = font;
    self.buttonItalic.imageView.image = nil;
    
    redColor = [MADColorEverydayApps newColorAnalogous4];
    self.buttonStrike.layer.borderColor = self.view.tintColor.CGColor;
    self.buttonStrike.layer.cornerRadius = CornerRadius;
    self.buttonStrike.layer.borderWidth = BorderWidth;
    [self.buttonStrike setTitle:@"\uf0cc" forState:UIControlStateNormal];
    [self.buttonStrike setTitle:@"\uf0cc" forState:UIControlStateSelected];
    [self.buttonStrike setTitle:@"\uf0cc" forState:UIControlStateHighlighted];
    [self.buttonStrike setTitleColor:redColor forState:UIControlStateHighlighted];
    [self.buttonStrike setTitleColor:self.view.tintColor forState:UIControlStateNormal];
    [self.buttonStrike setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    self.buttonStrike.titleLabel.font = font;
    self.buttonStrike.imageView.image = nil;
    
    redColor = [MADColorEverydayApps newColorAnalogous4];
    self.buttonUnderline.layer.borderColor = self.view.tintColor.CGColor;
    self.buttonUnderline.layer.cornerRadius = CornerRadius;
    self.buttonUnderline.layer.borderWidth = BorderWidth;
    [self.buttonUnderline setTitle:@"\uf0cd" forState:UIControlStateNormal];
    [self.buttonUnderline setTitle:@"\uf0cd" forState:UIControlStateSelected];
    [self.buttonUnderline setTitle:@"\uf0cd" forState:UIControlStateHighlighted];
    [self.buttonUnderline setTitleColor:redColor forState:UIControlStateHighlighted];
    [self.buttonUnderline setTitleColor:self.view.tintColor forState:UIControlStateNormal];
    [self.buttonUnderline setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    self.buttonUnderline.titleLabel.font = font;
    self.buttonUnderline.imageView.image = nil;
    
    _completedInitalLayout = NO;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length,
                                                   CGSizeZero.width,
                                                   self.bottomLayoutGuide.length,
                                                   CGSizeZero.width);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(self.topLayoutGuide.length,
                                                            CGSizeZero.width,
                                                            self.bottomLayoutGuide.length,
                                                            CGSizeZero.width);

    if (_completedInitalLayout == NO) {
        [self.tableView setContentOffset: CGPointMake(CGPointZero.x, -self.topLayoutGuide.length)
                                animated: NO];
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
        
        NSString *localizedNothingSelected = NSLocalizedString(@"Nothing Selected", @"Nothing Selected");
        NSString *localizedNothing = NSLocalizedString(@"Nothing", @"Nothing");
        
        NSAttributedString *attributedNothingSelected = [MADToolboxStrings newBoldSystemString: localizedNothingSelected];
        NSAttributedString *attributedNothing = [MADToolboxStrings newBoldSystemString: localizedNothing];
        
        self.labelFontName.attributedText = attributedNothingSelected;
        self.labelFontSize.attributedText = attributedNothing;
        
        
        NSArray *steppers = self.steppers;
        for (UIStepper *stepper in steppers) {
            stepper.userInteractionEnabled = NO;
        }
        
        NSAttributedString *labelSizeHeightAttributedText = [MADToolboxStrings newSizeHeightForValue: 0];
        self.labelSizeHeight.attributedText = labelSizeHeightAttributedText;
        
        NSAttributedString *labelSizeWidthAttributedText = [MADToolboxStrings newSizeWidthForValue: 0];
        self.labelSizeWidth.attributedText = labelSizeWidthAttributedText;
        
        NSAttributedString *labelBorderTopAttributedText = [MADToolboxStrings newMarginTopForValue: 0];
        self.labelBorderTop.attributedText = labelBorderTopAttributedText;
        
        NSAttributedString *labelBorderBottomAttributedText = [MADToolboxStrings newMarginBottomForValue: 0];
        self.labelBorderBottom.attributedText = labelBorderBottomAttributedText;
        
        NSAttributedString *labelBorderLeftAttributedText = [MADToolboxStrings newMarginLeftForValue: 0];
        self.labelBorderLeft.attributedText = labelBorderLeftAttributedText;
        
        NSAttributedString *labelBorderRightAttributedText = [MADToolboxStrings newMarginRightForValue: 0];
        self.labelBorderRight.attributedText = labelBorderRightAttributedText;
        
        NSAttributedString *labelMarginTopAttributedText = [MADToolboxStrings newMarginTopForValue: 0];
        self.labelMarginTop.attributedText = labelMarginTopAttributedText;
        
        NSAttributedString *labelMarginBottomAttributedText = [MADToolboxStrings newMarginBottomForValue: 0];
        self.labelMarginBottom.attributedText = labelMarginBottomAttributedText;
        
        NSAttributedString *labelMarginLeftAttributedText = [MADToolboxStrings newMarginLeftForValue: 0];
        self.labelMarginLeft.attributedText = labelMarginLeftAttributedText;
        
        NSAttributedString *labelMarginRightAttributedText = [MADToolboxStrings newMarginRightForValue: 0];
        self.labelMarginRight.attributedText = labelMarginRightAttributedText;
        
        NSAttributedString *labelPaddingTopAttributedText = [MADToolboxStrings newMarginTopForValue: 0];
        self.labelPaddingTop.attributedText = labelPaddingTopAttributedText;
        
        NSAttributedString *labelPaddingBottomAttributedText = [MADToolboxStrings newMarginBottomForValue: 0];
        self.labelPaddingBottom.attributedText = labelPaddingBottomAttributedText;
        
        NSAttributedString *labelPaddingLeftAttributedText = [MADToolboxStrings newMarginLeftForValue: 0];
        self.labelPaddingLeft.attributedText = labelPaddingLeftAttributedText;
        
        NSAttributedString *labelPaddingRightAttributedText = [MADToolboxStrings newMarginRightForValue: 0];
        self.labelPaddingRight.attributedText = labelPaddingRightAttributedText;
        
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
        
        MADAlignment_t alignmentHolder = MADAlignmentMake(MADHorizontalAlignmentUnknown,
                                                          MADVerticalAlignmentUnknown);
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
        NSAttributedString *atext = [MADToolboxStrings newMarginTopForValue: displayNumber];
        _labelMarginTop.attributedText = atext;
        _stepperMarginTop.value = marginHolder.top;
        
        displayNumber = numberOfMarginBottom == 1 ? marginHolder.bottom : 0;
        
        atext = [MADToolboxStrings newMarginBottomForValue: displayNumber];
        _labelMarginBottom.attributedText = atext;
        _stepperMarginBottom.value = marginHolder.bottom;
        
        displayNumber = numberOfMarginLeft == 1 ? marginHolder.left : 0;
        atext = [MADToolboxStrings newMarginLeftForValue: displayNumber];
        _labelMarginLeft.attributedText = atext;
        _stepperMarginLeft.value = marginHolder.left;
        
        displayNumber = numberOfMarginRight == 1 ? marginHolder.right : 0;
        atext = [MADToolboxStrings newMarginRightForValue: displayNumber];
        _labelMarginRight.attributedText = atext;
        _stepperMarginRight.value = marginHolder.right;
        
        displayNumber = numberOfPaddingTop == 1 ? paddingHolder.top : 0;
        atext = [MADToolboxStrings newMarginTopForValue: displayNumber];
        _labelPaddingTop.attributedText = atext;
        _stepperPaddingTop.value = paddingHolder.top;
        
        displayNumber = numberOfPaddingBottom == 1 ? paddingHolder.bottom : 0;
        atext = [MADToolboxStrings newMarginBottomForValue: displayNumber];
        _labelPaddingBottom.attributedText = atext;
        _stepperPaddingBottom.value = paddingHolder.bottom;
        
        displayNumber = numberOfPaddingLeft == 1 ? paddingHolder.left : 0;
        atext = [MADToolboxStrings newMarginLeftForValue: displayNumber];
        _labelPaddingLeft.attributedText = atext;
        _stepperPaddingLeft.value = paddingHolder.left;
        
        displayNumber = numberOfPaddingRight == 1 ? paddingHolder.right : 0;
        atext = [MADToolboxStrings newMarginRightForValue: displayNumber];
        _labelPaddingRight.attributedText = atext;
        _stepperPaddingRight.value = paddingHolder.right;
        
        displayNumber = numberOfBorderTop == 1 ? borderHolder.top : 0;
        atext = [MADToolboxStrings newMarginTopForValue: displayNumber];
        _labelBorderTop.attributedText = atext;
        _stepperBorderTop.value = borderHolder.top;
        
        displayNumber = numberOfBorderBottom == 1 ? borderHolder.bottom : 0;
        atext = [MADToolboxStrings newMarginBottomForValue: displayNumber];
        _labelBorderBottom.attributedText = atext;
        _stepperBorderBottom.value = borderHolder.bottom;
        
        displayNumber = numberOfBorderLeft == 1 ? borderHolder.left : 0;
        atext = [MADToolboxStrings newMarginLeftForValue: displayNumber];
        _labelBorderLeft.attributedText = atext;
        _stepperBorderLeft.value = borderHolder.left;
        
        displayNumber = numberOfBorderRight == 1 ? borderHolder.right : 0;
        atext = [MADToolboxStrings newMarginRightForValue: displayNumber];
        _labelBorderRight.attributedText = atext;
        _stepperBorderRight.value = borderHolder.right;
        
        displayNumber = numberOfSizeHeights == 1 ? sizeHolder.height : 0;
        atext = [MADToolboxStrings newSizeHeightForValue: displayNumber];
        _labelSizeHeight.attributedText = atext;
        _stepperSizeHeight.value = size.height;
        
        displayNumber = numberOfSizeWidths == 1 ? sizeHolder.width : 0;
        atext = [MADToolboxStrings newSizeWidthForValue: displayNumber];
        _labelSizeWidth.attributedText = atext;
        _stepperSizeWidth.value = size.width;
        
        
        UILabel *labelFontName = _labelFontName, *labelFontSize = _labelFontSize;
        NSAttributedString *display;
        switch (numberFonts) {
            case 0: {
                fontDisplayName = NSLocalizedString(@"Undefined", @"Undefined");
                display = [MADToolboxStrings newBoldSystemString:fontDisplayName];
                labelFontName.attributedText = display;
                break;
            }
            case 1: {
                display = [MADToolboxStrings newBoldSystemString:fontDisplayName];
                labelFontName.attributedText = display;
                display = [MADToolboxStrings newAttributedStringFontSizeInPoints: fontSizeHolder
                                                                    withFontSize: labelFontSize.font.pointSize];
                labelFontSize.attributedText = display;
                break;
            }
            default: {
                fontDisplayName = NSLocalizedString(@"Ambiguous", @"Ambiguous");
                display = [MADToolboxStrings newBoldSystemString:fontDisplayName];
                labelFontName.attributedText = display;
                display = [MADToolboxStrings newBoldSystemString:fontDisplayName];
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
    attributedString = [MADToolboxStrings newAttributedStringFontSizeInPoints: sender.value
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
    id display = [MADToolboxStrings newSizeWidthForValue:((UIStepper *)sender).value];
    self.labelSizeWidth.attributedText = display;
    [self.document.designerLayout updateElements:self.userSelectedObjectIDs
                                    setSizeWidth:(float)((UIStepper *)sender).value];
}

- (IBAction)handleContentHeightChanged:(id)sender {
    id display = [MADToolboxStrings newSizeHeightForValue:((UIStepper *)sender).value];
    self.labelSizeHeight.attributedText = display;
    [self.document.designerLayout updateElements:self.userSelectedObjectIDs
                                   setSizeHeight:(float)((UIStepper *)sender).value];
}

#pragma mark Margin

- (IBAction)handleMarginTopChanged:(id)sender {
    id display = [MADToolboxStrings newMarginTopForValue: ((UIStepper *)sender).value];
    self.labelMarginTop.attributedText = display;
    [self.document.designerLayout updateElements:self.userSelectedObjectIDs
                                    setMarginTop:(float)((UIStepper *)sender).value];
}

- (IBAction)handleMarginBottomChanged:(id)sender {
    id display = [MADToolboxStrings newMarginBottomForValue:((UIStepper *)sender).value];
    self.labelMarginBottom.attributedText = display;
    [self.document.designerLayout updateElements:self.userSelectedObjectIDs
                                 setMarginBottom:(float)((UIStepper *)sender).value];
}

- (IBAction)handleMarginLeftChanged:(id)sender {
    id display = [MADToolboxStrings newMarginLeftForValue: ((UIStepper *)sender).value];
    self.labelMarginLeft.attributedText = display;
    [self.document.designerLayout updateElements:self.userSelectedObjectIDs
                                   setMarginLeft:(float)((UIStepper *)sender).value];
}

- (IBAction)handleMarginRightChanged:(id)sender {
    id display = [MADToolboxStrings newMarginRightForValue: ((UIStepper *)sender).value];
    self.labelMarginRight.attributedText = display;
    [self.document.designerLayout updateElements:self.userSelectedObjectIDs
                                  setMarginRight:(float)((UIStepper *)sender).value];
}

#pragma mark Padding

- (IBAction)handlePaddingTopChanged:(id)sender {
    id display = [MADToolboxStrings newMarginTopForValue: ((UIStepper *)sender).value];
    self.labelPaddingTop.attributedText = display;
    [self.document.designerLayout updateElements:self.userSelectedObjectIDs
                                   setPaddingTop:(float)((UIStepper *)sender).value];
}

- (IBAction)handlePaddingBottomChanged:(id)sender {
    id display = [MADToolboxStrings newMarginBottomForValue:((UIStepper *)sender).value];
    self.labelPaddingBottom.attributedText = display;
    [self.document.designerLayout updateElements:self.userSelectedObjectIDs
                                setPaddingBottom:(float)((UIStepper *)sender).value];
}

- (IBAction)handlePaddingLeftChanged:(id)sender {
    id display = [MADToolboxStrings newMarginLeftForValue: ((UIStepper *)sender).value];
    self.labelPaddingLeft.attributedText = display;
    [self.document.designerLayout updateElements:self.userSelectedObjectIDs
                                  setPaddingLeft:(float)((UIStepper *)sender).value];
}

- (IBAction)handlePaddingRightChanged:(id)sender {
    id display = [MADToolboxStrings newMarginRightForValue: ((UIStepper *)sender).value];
    self.labelPaddingRight.attributedText = display;
    [self.document.designerLayout updateElements:self.userSelectedObjectIDs
                                 setPaddingRight:(float)((UIStepper *)sender).value];
}

#pragma mark Border

- (IBAction)handleBorderTopChanged:(id)sender {
    id display = [MADToolboxStrings newMarginTopForValue: ((UIStepper *)sender).value];
    self.labelBorderTop.attributedText = display;
    [self.document.designerLayout updateElements:self.userSelectedObjectIDs
                                    setBorderTop:(float)((UIStepper *)sender).value];
}

- (IBAction)handleBorderBottomChanged:(id)sender {
    id display = [MADToolboxStrings newMarginBottomForValue:((UIStepper *)sender).value];
    self.labelBorderBottom.attributedText = display;
    [self.document.designerLayout updateElements:self.userSelectedObjectIDs
                                 setBorderBottom:(float)((UIStepper *)sender).value];
}

- (IBAction)handleBorderLeftChanged:(id)sender {
    id display = [MADToolboxStrings newMarginLeftForValue: ((UIStepper *)sender).value];
    self.labelBorderLeft.attributedText = display;
    [self.document.designerLayout updateElements:self.userSelectedObjectIDs
                                   setBorderLeft:(float)((UIStepper *)sender).value];
}

- (IBAction)handleBorderRightChanged:(id)sender {
    id display = [MADToolboxStrings newMarginRightForValue: ((UIStepper *)sender).value];
    self.labelBorderRight.attributedText = display;
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:MADIdentifierStoryboardSeguePushFontPicker]) {
        
        MADFontSelectorViewController *destination = segue.destinationViewController;
        destination.delegate = self;
        destination.clearsBackground = self.clearsBackground;
        NSManagedObjectContext *context = _document.managedObjectContext;
        NSString *fontname = nil;
        NSNumber *identifier;
        RptqDocumentElement *element;
        for (identifier in self.userSelectedObjectIDs) {
            element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                          fromObjectContext:context];
            fontname = element.fontname.copy;
            break;
        }
        [destination setFamilyName:fontname];
    }
}

@end

@implementation MADToolboxStrings

static NSString * const FormatPoints = @"%#.1f pt";
static NSString * const CommentPoints = @"Like '5.2 points.'";
static NSString * const DialogLeft = @"Left";
static NSString * const DialogSpace = @"--";

+ (instancetype)newSystemString:(NSString *)string {

    UIFont *font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
    NSDictionary *boldAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                                font, NSFontAttributeName, nil];
    if (string == nil) { string = @""; }
    id localizedAttributedMessage = [[NSAttributedString alloc] initWithString: string
                                                                    attributes: boldAttributes];
    return localizedAttributedMessage;
}

+ (instancetype)newBoldSystemString:(NSString *)string {
    UIFont *boldFont = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
    NSDictionary *boldAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                            boldFont, NSFontAttributeName, nil];
    if (string == nil) { string = @""; }
    id localizedAttributedMessage = [[NSAttributedString alloc] initWithString: string
                                                                    attributes: boldAttributes];
    return localizedAttributedMessage;
}

+ (instancetype)newStringForSubject:(NSString *)subject value:(NSString *)value {
    NSAttributedString *boldSubject = [MADToolboxStrings newBoldSystemString:subject];
    NSString *spaceAndValue = [@" " stringByAppendingString:value];
    NSAttributedString *normalValue = [MADToolboxStrings newSystemString: spaceAndValue];
    id result = [[NSMutableAttributedString alloc] initWithAttributedString:boldSubject];
    [result appendAttributedString:normalValue];
    return result;
}

+ (instancetype)newSizeWidthForValue:(double)value {
    NSString *DialogWidth = @"Width";
    NSString *width = NSLocalizedString(DialogWidth, DialogWidth);
    NSString *stringValue;
    if (value <= 0) {
        stringValue = DialogSpace;
    } else {
        NSString *pointsFormat = NSLocalizedString(FormatPoints, CommentPoints);
        stringValue = [[NSString alloc] initWithFormat:pointsFormat, value];
    }
    id newSize = [MADToolboxStrings newStringForSubject:width value:stringValue];
    return newSize;
}

+ (instancetype)newSizeHeightForValue:(double)value {
    NSString *DialogHeight = @"Height";
    NSString *height = NSLocalizedString(DialogHeight, DialogHeight);
    NSString *stringValue;
    if (value <= 0) {
        stringValue = DialogSpace;
    } else {
        NSString *pointsFormat = NSLocalizedString(FormatPoints, CommentPoints);
        stringValue = [[NSString alloc] initWithFormat:pointsFormat, value];
    }
    id newSize = [MADToolboxStrings newStringForSubject:height value:stringValue];
    return newSize;
}

+ (instancetype)newMarginTopForValue:(double)value {
    NSString *DialogTop = @"Top";
    NSString *top = NSLocalizedString(DialogTop, DialogTop);
    NSString *stringValue;
    if (value <= 0) {
        stringValue = DialogSpace;
    } else {
        NSString *pointsFormat = NSLocalizedString(FormatPoints, CommentPoints);
        stringValue = [[NSString alloc] initWithFormat:pointsFormat, value];
    }
    id newMargin = [MADToolboxStrings newStringForSubject:top value:stringValue];
    return newMargin;
}

+ (instancetype)newMarginBottomForValue:(double)value {
    NSString *DialogBottom = @"Bottom";
    NSString *bottom = NSLocalizedString(DialogBottom, DialogBottom);
    NSString *stringValue;
    if (value <= 0) {
        stringValue = DialogSpace;
    } else {
        NSString *pointsFormat = NSLocalizedString(FormatPoints, CommentPoints);
        stringValue = [[NSString alloc] initWithFormat:pointsFormat, value];
    }
    id newMargin = [MADToolboxStrings newStringForSubject:bottom value:stringValue];
    return newMargin;
}

+ (instancetype)newMarginLeftForValue:(double)value {
    NSString *left = NSLocalizedString(DialogLeft, DialogLeft);
    NSString *stringValue;
    if (value <= 0) {
        stringValue = DialogSpace;
    } else {
        NSString *pointsFormat = NSLocalizedString(FormatPoints, CommentPoints);
        stringValue = [[NSString alloc] initWithFormat:pointsFormat, value];
    }
    id newMargin = [MADToolboxStrings newStringForSubject:left value:stringValue];
    return newMargin;
}

+ (instancetype)newMarginRightForValue:(double)value {
    NSString *DialogRight = @"Right";
    NSString *right = NSLocalizedString(DialogRight, DialogRight);
    NSString *stringValue;
    if (value <= 0) {
        stringValue = DialogSpace;
    } else {
        NSString *pointsFormat = NSLocalizedString(FormatPoints, CommentPoints);
        stringValue = [[NSString alloc] initWithFormat:pointsFormat, value];
    }
    id newMargin = [MADToolboxStrings newStringForSubject:right value:stringValue];
    return newMargin;
}

+ (instancetype)newAttributedStringFontSizeInPoints:(double)pointsDisplay
                                       withFontSize:(CGFloat)pointSize {
    
    UIFont *boldFont = [UIFont boldSystemFontOfSize:pointSize];
    UIFont *systemFont = [UIFont systemFontOfSize:pointSize];
    NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                        boldFont, NSFontAttributeName, nil];

    id localizedAttributedMessage;
    NSString *message = NSLocalizedString(@"Font size", "Font size");
    localizedAttributedMessage = [[NSMutableAttributedString alloc] initWithString: message
                                                                        attributes: attributes];
    
    message = NSLocalizedString(@"%#.1f pt", @"%#.1f points");
    message = [@" " stringByAppendingFormat:message, pointsDisplay];
    attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                        systemFont, NSFontAttributeName, nil];
    NSAttributedString *suffix = [[NSAttributedString alloc] initWithString: message
                                                                 attributes: attributes];
    
    [localizedAttributedMessage appendAttributedString:suffix];
    return localizedAttributedMessage;
}

@end
