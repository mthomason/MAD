//
//  fontSettingsTableViewController.m
//  Reports
//
//  Created by Michael Thomason on 1/5/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADToolboxStyleViewController.h"

#import <QuartzCore/CALayer.h>

#import <CoreData/NSManagedObjectContext.h>

#import <UIKit/NSAttributedString.h>
#import <UIKit/UIStepper.h>
#import <UIKit/UISegmentedControl.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIButton.h>
#import <UIKit/UIStoryboardSegue.h>

#import <MADCocoaExtensions/MADMargin.h>
#import <MADCocoaExtensions/MADPadding.h>
#import <MADCocoaExtensions/MADTextStyle.h>

#import <MAD/MADocument.h>
#import <MAD/MADFont.h>
#import <MAD/RptqDocumentElement.h>
#import <MAD/RptqDocumentElement+Extras.h>
#import <MAD/MADAlignment.h>

#import "MADControlState.h"

#import "MADReportDesignerFontSelectorDelegateProtocol.h"

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

@end

const NSInteger MADTagStepperPaddingTop     = 1;
const NSInteger MADTagStepperPaddingBottom  = 3;
const NSInteger MADTagStepperPaddingLeft    = 15;
const NSInteger MADTagStepperPaddingRight   = 31;

const NSInteger MADTagStepperMarginTop      = 63;
const NSInteger MADTagStepperMarginBottom   = 127;
const NSInteger MADTagStepperMarginLeft     = 255;
const NSInteger MADTagStepperMarginRight    = 511;

const NSInteger MADIDTagStepperSizeWidth    = 1023;
const NSInteger MADIDTagStepperSizeHeight   = 2047;

const NSInteger MADIDTagStepperFontSize     = 4095;

const NSInteger MADIDTagSegmentedControlHorizontalAlignment     = 8191;
const NSInteger MADIDTagSegmentedControlVerticalAlignment       = 16383;


@interface MADToolboxStyleViewController()
    <UITableViewDelegate>

    @property (assign) MTControlState controlStateBold;
    @property (assign) MTControlState controlStateItalic;
    @property (assign) MTControlState controlStateStrike;
    @property (assign) MTControlState controlStateUnderline;

    @property (nonatomic, strong) NSSet *userSelectedObjectIDs;

    @property (nonatomic, weak) IBOutlet UITableViewCell *fontLabelTableViewCell;
    @property (nonatomic, weak) IBOutlet UILabel *labelFontSize;
    @property (nonatomic, weak) IBOutlet UIStepper *stepperFontSize;
    @property (nonatomic, weak) IBOutlet UIButton *buttonBold;
    @property (nonatomic, weak) IBOutlet UIButton *buttonItalic;
    @property (nonatomic, weak) IBOutlet UIButton *buttonStrike;
    @property (nonatomic, weak) IBOutlet UIButton *buttonUnderline;

    @property (nonatomic, weak) IBOutlet UILabel *labelPaddingTop;
    @property (nonatomic, weak) IBOutlet UILabel *labelPaddingBottom;
    @property (nonatomic, weak) IBOutlet UILabel *labelPaddingLeft;
    @property (nonatomic, weak) IBOutlet UILabel *labelPaddingRight;

    @property (nonatomic, weak) IBOutlet UILabel *labelMarginTop;
    @property (nonatomic, weak) IBOutlet UILabel *labelMarginBottom;
    @property (nonatomic, weak) IBOutlet UILabel *labelMarginLeft;
    @property (nonatomic, weak) IBOutlet UILabel *labelMarginRight;
    @property (nonatomic, weak) IBOutlet UILabel *labelSizeWidth;
    @property (nonatomic, weak) IBOutlet UILabel *labelSizeHeight;

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
    @property (nonatomic, weak) IBOutlet UISegmentedControl *segmentedControlVerticalAlignment;

    @property (nonatomic, weak) IBOutletCollection(UITableViewCell) NSArray *groupTableViewCellStyle;
    @property (nonatomic, weak) IBOutletCollection(UITableViewCell) NSArray *groupTableViewCellLayout;

    @property (nonatomic, weak) IBOutletCollection(UIStepper) NSArray *steppers;

    @property (nonatomic, assign) BOOL completedInitalLayout;

    - (IBAction)controlValueChanged:(id)sender;

@end

@implementation MADToolboxStyleViewController

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    
    self.stepperPaddingTop.tag = MADTagStepperPaddingTop;
    self.stepperPaddingBottom.tag = MADTagStepperPaddingBottom;
    self.stepperPaddingLeft.tag = MADTagStepperPaddingLeft;
    self.stepperPaddingRight.tag = MADTagStepperPaddingRight;
    
    self.stepperMarginTop.tag = MADTagStepperMarginTop;
    self.stepperMarginBottom.tag = MADTagStepperMarginBottom;
    self.stepperPaddingLeft.tag = MADTagStepperMarginLeft;
    self.stepperPaddingRight.tag = MADTagStepperMarginRight;
    
    self.stepperSizeWidth.tag = MADIDTagStepperSizeWidth;
    self.stepperSizeHeight.tag = MADIDTagStepperSizeHeight;
    
    self.stepperFontSize.tag = MADIDTagStepperFontSize;
    
    self.segmentedControlHorizontalAlignment.tag = MADIDTagSegmentedControlHorizontalAlignment;
    self.segmentedControlVerticalAlignment.tag = MADIDTagSegmentedControlVerticalAlignment;
    
    UIColor *tintColor = self.view.tintColor.copy;
    self.buttonBold.layer.borderColor = tintColor.CGColor;
    self.buttonBold.layer.cornerRadius = CornerRadius;
    self.buttonBold.layer.borderWidth = BorderWidth;
    
    self.buttonItalic.layer.borderColor = tintColor.CGColor;
    self.buttonItalic.layer.cornerRadius = CornerRadius;
    self.buttonItalic.layer.borderWidth = BorderWidth;
    
    self.buttonStrike.layer.borderColor = tintColor.CGColor;
    self.buttonStrike.layer.cornerRadius = CornerRadius;
    self.buttonStrike.layer.borderWidth = BorderWidth;
    
    self.buttonUnderline.layer.borderColor = tintColor.CGColor;
    self.buttonUnderline.layer.cornerRadius = CornerRadius;
    self.buttonUnderline.layer.borderWidth = BorderWidth;
    
    self.completedInitalLayout = NO;
    
    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width, self.bottomLayoutGuide.length, CGSizeZero.width);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width, self.bottomLayoutGuide.length, CGSizeZero.width);

    if (self.completedInitalLayout == NO) {
        [self.tableView setContentOffset: CGPointMake(CGPointZero.x, -self.topLayoutGuide.length) animated: NO];
        self.completedInitalLayout = YES;
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
            select = NO;
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
    
     control.selected = select;
     control.highlighted = highlight;
    
    if ([control isKindOfClass:[UIButton class]]) {
        control.backgroundColor = backgroundColor;
        control.tintColor = titleColor;
        ((UIButton *)control).titleLabel.textColor = titleColor;
    }
    
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);

    UIControl * __weak weakControl = control;
    dispatch_async(queuePriorityBackground, ^{
        
        UIControl * strongControl = weakControl;
        UIControl * __weak weakControl2 = strongControl;
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            UIControl *strongControl2 = weakControl2;
            if (strongControl2) {
                strongControl2.selected = select;
                strongControl2.highlighted = highlight;
                
                if ([strongControl2 isKindOfClass:[UIButton class]]) {
                    strongControl2.backgroundColor = backgroundColor;
                    
                    strongControl2.tintColor = titleColor;
                    
                    ((UIButton *)strongControl2).titleLabel.textColor = titleColor;
                }
            }
            
        }];
        
    });
    
    
}

- (void)setSelectedDocumentObjects:(NSSet *)objectIds {
    self.userSelectedObjectIDs = objectIds;
    [self updateDisplay];

}

- (void)updateSegmentedControlVerticalAlignmentNotSelected {
    UISegmentedControl *segmentedControlVerticalAlignment;
    segmentedControlVerticalAlignment = _segmentedControlVerticalAlignment;
    segmentedControlVerticalAlignment.selected = NO;
    segmentedControlVerticalAlignment.highlighted = NO;
    
    segmentedControlVerticalAlignment.selectedSegmentIndex = UISegmentedControlNoSegment;
    segmentedControlVerticalAlignment.userInteractionEnabled = NO;
}

- (void)updateSegmentedControlVerticalAlignmentWithChosenIndex:(NSInteger)index {
    _segmentedControlVerticalAlignment.selectedSegmentIndex = index;
}

- (void)updateDisplay {

    if (!self.isViewLoaded) return;
    
    
    UISegmentedControl *segmentedControlHorizontalAlignment, *segmentedControlVerticalAlignment;
    segmentedControlHorizontalAlignment = _segmentedControlHorizontalAlignment;
    segmentedControlVerticalAlignment = _segmentedControlVerticalAlignment;
    
    void(^updateControlsEnabled)(BOOL) = ^void(BOOL enabled) {
        self.buttonItalic.      enabled = enabled;
        self.buttonBold.        enabled = enabled;
        self.buttonStrike.      enabled = enabled;
        self.buttonUnderline.   enabled = enabled;
        self.buttonBold.selected = enabled;
        self.buttonBold.highlighted = enabled;
        
        self.buttonItalic.selected = enabled;
        self.buttonItalic.highlighted = enabled;
        
        self.buttonStrike.selected = enabled;
        self.buttonStrike.highlighted = enabled;
        
        self.buttonUnderline.selected = enabled;
        self.buttonUnderline.highlighted = enabled;
        
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
        
        [self updateSegmentedControlVerticalAlignmentNotSelected];
        
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
        
        MADMargin *marginHolder = [[MADMargin alloc] initWithLeft: -1
                                                            right: -1
                                                              top: -1
                                                           bottom: -1];
        MADPadding *paddingHolder = [[MADPadding alloc] initWithLeft: -1
                                                               right: -1
                                                                 top: -1
                                                              bottom: -1];
        
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
        
        //MADMargin_t margin; MADLayoutPadding_t padding; CGSize size; MADAlignment_t alignment;
        //MADTextStyle_t textStyle;
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
                
                [(NSValue *)documentObject.size getValue:&size];
                
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

                if (size.width != sizeHolder.width ) {
                    sizeHolder.width = size.width;
                    numberOfSizeWidths++;
                }

                if (size.height != sizeHolder.height ) {
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
                
                documentObject.style.bold ? numberBold++ : numberNotBold++;
                documentObject.style.underline ? numberUnderline++ : numberNotUnderline++;
                documentObject.style.strikethrough ? numberStrike++ : numberNotStrike++;
                documentObject.style.italic ? numberItalic++ : numberNotItalic++;
                
            }
            
        }
        
        segmentedControlHorizontalAlignment.selectedSegmentIndex = documentObject.alignment.horizontal;
        [self updateSegmentedControlVerticalAlignmentWithChosenIndex:documentObject.alignment.vertical];
        
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
        
        displayNumber = numberOfSizeHeights == 1 ? sizeHolder.height : 0;
        NSAttributedString *labelSizeHeightAttributedText = [MADToolboxStrings newSizeHeightForValue: displayNumber];
        _labelSizeHeight.attributedText = labelSizeHeightAttributedText;
        _stepperSizeHeight.value = size.height;
        
        displayNumber = numberOfSizeWidths == 1 ? sizeHolder.width : 0;
        NSAttributedString *labelSizeWidthAttributedText = [MADToolboxStrings newSizeWidthForValue: displayNumber];
        _labelSizeWidth.attributedText = labelSizeWidthAttributedText;
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
                display = [MADToolboxStyleViewController newAttributedStringFontSizeInPoints: fontSizeHolder
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
        
        MTControlState controlStateHorizontalAlignment = numberOfHorazontalAlignments > 0 ? (numberOfHorazontalAlignments == 1 ? MTControlStateOn : MTControlStateAmbiguous) : MTControlStateOff;
        MTControlState controlStateVerticalAlignment = numberOfVerticalAlignments > 0 ? (numberOfVerticalAlignments == 1 ? MTControlStateOn : MTControlStateAmbiguous) : MTControlStateOff;
        
        // FIXME: Needs ambigious state for segmented control.
        
        /*
         if (controlStateHorizontalAlignment == MTControlStateAmbiguous) {
         [_segmentedControlHorizontalAlignment setSelectedSegmentIndex:UISegmentedControlNoSegment];
         UIColor *tentColor = [[MADColorEverydayApps newColor] colorWithAlphaComponent:0.5000f];
         _segmentedControlHorizontalAlignment.backgroundColor = tentColor;
         } else {
         //[_segmentedControlHorizontalAlignment setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
         _segmentedControlHorizontalAlignment.backgroundColor = [UIColor clearColor];
         }
         if (controlStateVerticalAlignment == MTControlStateAmbiguous) {
         //UIImage *imageButtonSelected = [UIImage imageNamed:@"UIButtonSelected"];
         [_segmentedControlVerticalAlignment setSelectedSegmentIndex:UISegmentedControlNoSegment];
         //[_segmentedControlVerticalAlignment setBackgroundImage:[imageButtonSelected resizableImage] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
         UIColor *tentColor = [[MADColorEverydayApps newColor] colorWithAlphaComponent:0.5000f];
         _segmentedControlVerticalAlignment.backgroundColor = tentColor;
         } else {
         //[_segmentedControlVerticalAlignment setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
         _segmentedControlVerticalAlignment.backgroundColor = [UIColor clearColor];
         }
         */
        
        
        [self setStateInControl:segmentedControlHorizontalAlignment forState:controlStateHorizontalAlignment];
        [self setStateInControl:segmentedControlVerticalAlignment forState:controlStateVerticalAlignment];
        
        _fontLabelTableViewCell.userInteractionEnabled = YES;
        stepperFontSize.userInteractionEnabled = YES;
        segmentedControlHorizontalAlignment.userInteractionEnabled = YES;
        segmentedControlVerticalAlignment.userInteractionEnabled = YES;
        
    }
    [self setStateInControl: _buttonBold        forState: _controlStateBold];
    [self setStateInControl: _buttonItalic      forState: _controlStateItalic];
    [self setStateInControl: _buttonStrike      forState: _controlStateStrike];
    [self setStateInControl: _buttonUnderline   forState: _controlStateUnderline];
}

+ (NSAttributedString *)newAttributedStringFontSizeInPoints:(double)pointsDisplay
                                               withFontSize:(CGFloat)pointSize {
    
    
    UIFont *boldFont = [UIFont boldSystemFontOfSize:pointSize];
    UIFont *systemFont = [UIFont systemFontOfSize:pointSize];
    NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                        boldFont, NSFontAttributeName, nil];

    NSMutableAttributedString *localizedAttributedMessage;
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

- (void)chooseFamilyName:(NSString *)familyName {
    CGFloat systemFontSize = [UIFont systemFontSize];
    UIFont *font = [UIFont fontWithName:familyName size:systemFontSize];

    UILabel *labelFontName = _labelFontName;

    labelFontName.font = font;
    labelFontName.text = familyName;

    NSManagedObjectContext *context = _document.managedObjectContext;
    RptqDocumentElement *element;
    NSSet <NSNumber *> *userSelectedObjectIDs;
    userSelectedObjectIDs = userSelectedObjectIDs;
    NSNumber *identifier;
    for (identifier in userSelectedObjectIDs) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:context];
        element.fontname = familyName;
    }
    [context save:nil];
}

- (IBAction)toggleBold:(id)sender {

    switch (self.controlStateBold) {
        case MTControlStateOn:
            self.controlStateBold = MTControlStateOff;
            break;
        case MTControlStateOff:
            self.controlStateBold = MTControlStateOn;
            break;
        case MTControlStateAmbiguous:
            self.controlStateBold = MTControlStateOn;
            break;
        default:
            self.controlStateBold = MTControlStateOn;
            break;
    }
    [self setStateInControl:self.buttonBold forState:self.controlStateBold];
    
    NSManagedObjectContext *context = _document.managedObjectContext;
    RptqDocumentElement *element;
    NSSet <NSNumber *> *userSelectedObjectIDs;
    userSelectedObjectIDs = userSelectedObjectIDs;
    NSNumber *identifier;
    for (identifier in userSelectedObjectIDs) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:context];
        element.style.bold = self.controlStateBold;
    }
    [context save:nil];
}

- (IBAction)toggleItalic:(id)sender {
    switch (self.controlStateItalic) {
        case MTControlStateOn:
            self.controlStateItalic = MTControlStateOff;
            break;
        case MTControlStateOff:
            self.controlStateItalic = MTControlStateOn;
            break;
        case MTControlStateAmbiguous:
            self.controlStateItalic = MTControlStateOn;
            break;
        default:
            self.controlStateItalic = MTControlStateOn;
            break;
    }
    [self setStateInControl:self.buttonItalic forState:self.controlStateItalic];

    NSManagedObjectContext *context = _document.managedObjectContext;
    RptqDocumentElement *element;
    NSSet <NSNumber *> *userSelectedObjectIDs;
    userSelectedObjectIDs = userSelectedObjectIDs;
    NSNumber *identifier;
    for (identifier in userSelectedObjectIDs) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:context];
        element.style.italic = self.controlStateItalic;
    }
    [context save:nil];
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
    
    NSManagedObjectContext *context = _document.managedObjectContext;
    RptqDocumentElement *element;
    NSSet <NSNumber *> *userSelectedObjectIDs;
    userSelectedObjectIDs = userSelectedObjectIDs;
    NSNumber *identifier;
    for (identifier in userSelectedObjectIDs) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:context];
        element.style.strikethrough = ControlStateIsOn(_controlStateStrike);
    }
    [context save:nil];
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
    
    NSManagedObjectContext *context = _document.managedObjectContext;
    RptqDocumentElement *element;
    NSSet <NSNumber *> *userSelectedObjectIDs;
    userSelectedObjectIDs = userSelectedObjectIDs;
    NSNumber *identifier;
    for (identifier in userSelectedObjectIDs) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:context];
        element.style.underline = ControlStateIsOn(_controlStateUnderline);
    }
    [context save:nil];
}

- (void)emptySelector:(id)whofuckingCares { }

- (void)updateLabelFontSize:(double)pointSize {
    UILabel *labelFontSize = _labelFontSize;
    NSAttributedString *attributedString;
    attributedString = [MADToolboxStyleViewController newAttributedStringFontSizeInPoints: pointSize
                                                                             withFontSize: labelFontSize.font.pointSize];
    labelFontSize.attributedText = attributedString;
    NSManagedObjectContext *context = _document.managedObjectContext;
    RptqDocumentElement *element;
    NSSet <NSNumber *> *userSelectedObjectIDs;
    userSelectedObjectIDs = userSelectedObjectIDs;
    NSNumber *identifier;
    for (identifier in userSelectedObjectIDs) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:context];
        element.fontsize = pointSize;
    }
    [context save:nil];
}

- (void)updateLabelSizeHeight:(double)height {
    NSAttributedString *displayHeight = [MADToolboxStrings newSizeHeightForValue:height];
    self.labelSizeHeight.attributedText = displayHeight;
    NSManagedObjectContext *context = _document.managedObjectContext;
    RptqDocumentElement *element;
    NSSet <NSNumber *> *userSelectedObjectIDs;
    userSelectedObjectIDs = userSelectedObjectIDs;
    NSNumber *identifier;
    for (identifier in userSelectedObjectIDs) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:context];
        [element setSizeHeight: height];
    }
    [context save:nil];
}

- (void)updateLabelSizeWidth:(double)width {
    NSAttributedString *displayWidth = [MADToolboxStrings newSizeWidthForValue:width];
    self.labelSizeWidth.attributedText = displayWidth;
    NSManagedObjectContext *context = _document.managedObjectContext;
    RptqDocumentElement *element;
    NSSet <NSNumber *> *userSelectedObjectIDs;
    userSelectedObjectIDs = userSelectedObjectIDs;
    NSNumber *identifier;
    for (identifier in userSelectedObjectIDs) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:context];
        [element setSizeWidth: width];
    }
    [context save:nil];
}

- (void)updateHorizontalAlignment:(NSInteger)index {
    [self.segmentedControlHorizontalAlignment setBackgroundImage: nil forState: UIControlStateNormal
                                                      barMetrics: UIBarMetricsDefault];
    NSManagedObjectContext *context = _document.managedObjectContext;
    RptqDocumentElement *element;
    NSSet <NSNumber *> *userSelectedObjectIDs;
    userSelectedObjectIDs = userSelectedObjectIDs;
    NSNumber *identifier;
    for (identifier in userSelectedObjectIDs) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:context];
        element.alignment.horizontal = (MADHorizontalAlignment)index;
    }
    [context save:nil];
}

- (void)updateVerticalAlignment:(NSInteger)index {
    [self.segmentedControlVerticalAlignment setBackgroundImage: nil forState: UIControlStateNormal
                                                    barMetrics: UIBarMetricsDefault];
    NSManagedObjectContext *context = _document.managedObjectContext;
    RptqDocumentElement *element;
    NSSet <NSNumber *> *userSelectedObjectIDs;
    userSelectedObjectIDs = userSelectedObjectIDs;
    NSNumber *identifier;
    for (identifier in userSelectedObjectIDs) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:context];
        element.alignment.vertical = (MADVerticalAlignment)index;
    }
    [context save:nil];
}

- (void)updatePaddingTop:(double)top {
    NSAttributedString *display = [MADToolboxStrings newMarginTopForValue:top];
    self.labelPaddingTop.attributedText = display;
    NSManagedObjectContext *context = _document.managedObjectContext;
    RptqDocumentElement *element;
    NSSet <NSNumber *> *userSelectedObjectIDs;
    userSelectedObjectIDs = userSelectedObjectIDs;
    NSNumber *identifier;
    for (identifier in userSelectedObjectIDs) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:context];
        element.padding.top = top;
    }
    [context save:nil];
}

- (void)updatePaddingBottom:(double)bottom {
    NSAttributedString *display = [MADToolboxStrings newMarginBottomForValue:bottom];
    self.labelPaddingBottom.attributedText = display;
    NSManagedObjectContext *context = _document.managedObjectContext;
    RptqDocumentElement *element;
    NSSet <NSNumber *> *userSelectedObjectIDs;
    userSelectedObjectIDs = userSelectedObjectIDs;
    NSNumber *identifier;
    for (identifier in userSelectedObjectIDs) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:context];
        element.padding.bottom = bottom;
    }
    [context save:nil];
}

- (void)updatePaddingLeft:(double)left {
    NSAttributedString *display = [MADToolboxStrings newMarginLeftForValue:left];
    self.labelPaddingLeft.attributedText = display;
    NSManagedObjectContext *context = _document.managedObjectContext;
    RptqDocumentElement *element;
    NSSet <NSNumber *> *userSelectedObjectIDs;
    userSelectedObjectIDs = userSelectedObjectIDs;
    NSNumber *identifier;
    for (identifier in userSelectedObjectIDs) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:context];
        element.padding.left = left;
    }
    [context save:nil];
}

- (void)updatePaddingRight:(double)right {
    NSAttributedString *display = [MADToolboxStrings newMarginRightForValue:right];
    self.labelPaddingRight.attributedText = display;
    NSManagedObjectContext *context = _document.managedObjectContext;
    RptqDocumentElement *element;
    NSSet <NSNumber *> *userSelectedObjectIDs;
    userSelectedObjectIDs = userSelectedObjectIDs;
    NSNumber *identifier;
    for (identifier in userSelectedObjectIDs) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:context];
        element.padding.right = right;
    }
    [context save:nil];
}

- (void)updateMarginTop:(double)top {
    NSAttributedString *display = [MADToolboxStrings newMarginTopForValue: top];
    self.labelMarginTop.attributedText = display;
    NSManagedObjectContext *context = _document.managedObjectContext;
    RptqDocumentElement *element;
    NSSet <NSNumber *> *userSelectedObjectIDs;
    userSelectedObjectIDs = userSelectedObjectIDs;
    NSNumber *identifier;
    for (identifier in userSelectedObjectIDs) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:context];
        element.margin.top = top;
    }
    [context save:nil];
}

- (void)updateMarginBottom:(double)bottom {
    NSAttributedString *display = [MADToolboxStrings newMarginBottomForValue:bottom];
    self.labelMarginBottom.attributedText = display;
    NSManagedObjectContext *context = _document.managedObjectContext;
    RptqDocumentElement *element;
    NSSet <NSNumber *> *userSelectedObjectIDs;
    userSelectedObjectIDs = userSelectedObjectIDs;
    NSNumber *identifier;
    for (identifier in userSelectedObjectIDs) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:context];
        element.margin.bottom = bottom;
    }
    [context save:nil];
}

- (void)updateMarginLeft:(double)left {
    NSAttributedString *display = [MADToolboxStrings newMarginLeftForValue: left];
    self.labelMarginLeft.attributedText = display;
    NSManagedObjectContext *context = _document.managedObjectContext;
    RptqDocumentElement *element;
    NSSet <NSNumber *> *userSelectedObjectIDs;
    userSelectedObjectIDs = userSelectedObjectIDs;
    NSNumber *identifier;
    for (identifier in userSelectedObjectIDs) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:context];
        element.margin.left = left;
    }
    [context save:nil];
}

- (void)updateMarginRight:(double)right {
    NSAttributedString *display = [MADToolboxStrings newMarginRightForValue: right];
    self.labelMarginRight.attributedText = display;
    NSManagedObjectContext *context = _document.managedObjectContext;
    RptqDocumentElement *element;
    NSSet <NSNumber *> *userSelectedObjectIDs;
    userSelectedObjectIDs = userSelectedObjectIDs;
    NSNumber *identifier;
    for (identifier in userSelectedObjectIDs) {
        element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
                                                      fromObjectContext:context];
        element.margin.right = right;
    }
    [context save:nil];
}


- (IBAction)controlValueChanged:(UIControl *)sender {
    
    switch (sender.tag) {
            
        case MADTagStepperPaddingTop:
            [self updatePaddingTop:((UIStepper *)sender).value];
            break;
            
        case MADTagStepperPaddingBottom:
            [self updatePaddingBottom:((UIStepper *)sender).value];
            break;
            
        case MADTagStepperPaddingLeft:
            [self updatePaddingLeft:((UIStepper *)sender).value];
            break;
            
        case MADTagStepperPaddingRight:
            [self updatePaddingRight:((UIStepper *)sender).value];
            break;

        case MADTagStepperMarginTop:
            [self updateMarginTop:((UIStepper *)sender).value];
            break;

        case MADTagStepperMarginBottom:
            [self updateMarginBottom:((UIStepper *)sender).value];
            break;
            
        case MADTagStepperMarginLeft:
            [self updateMarginLeft:((UIStepper *)sender).value];
            break;
            
        case MADTagStepperMarginRight:
            [self updateMarginRight:((UIStepper *)sender).value];
            break;
            
        case MADIDTagStepperSizeWidth:
            [self updateLabelSizeWidth:((UIStepper *)sender).value];
            break;
            
        case MADIDTagStepperSizeHeight:
            [self updateLabelSizeHeight:((UIStepper *)sender).value];
            break;
            
        case MADIDTagStepperFontSize:
            [self updateLabelFontSize:((UIStepper *)sender).value];
            break;
            
        case MADIDTagSegmentedControlHorizontalAlignment:
            [self updateHorizontalAlignment:((UISegmentedControl *)sender).selectedSegmentIndex];
            break;

        case MADIDTagSegmentedControlVerticalAlignment:
            [self updateVerticalAlignment:((UISegmentedControl *)sender).selectedSegmentIndex];
            break;
            
        default:
            break;
    }
    

}

- (void)tableViewControllerDidUpdateFontToFontWithName:(NSString *)fontName {
    [self chooseFamilyName:fontName];
}

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

@end
