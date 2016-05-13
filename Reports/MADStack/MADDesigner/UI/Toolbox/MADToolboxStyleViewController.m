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
#import "MADControlState.h"
#import <CoreData/NSManagedObjectContext.h>
#import <MAD/MADocument.h>
#import <MAD/MADFont.h>
#import <MAD/RptqDocumentObject.h>
#import <MAD/RptqDocumentObject+Extras.h>
#import <MAD/NSManagedObject+Extras.h>

static const CGFloat CornerRadius = 6.6666f;
static const CGFloat BorderWidth = 1.0000f;

static NSString * const MADIdentifierStoryboardSeguePushFontPicker = @"MADIdentifierStoryboardSeguePushFontPicker";

static NSString * const FormatPoints = @"%#.1f pt";
static NSString * const CommentPoints = @"Like '5.2 points.'";
static NSString * const DialogWidth = @"Width";
static NSString * const DialogHeight = @"Height";
static NSString * const DialogBottom = @"Bottom";
static NSString * const DialogTop = @"Top";
static NSString * const DialogLeft = @"Left";
static NSString * const DialogRight = @"Right";
static NSString * const DialogSpace = @"--";

static inline BOOL ControlStateIsOn(MTControlState controlState);
static inline BOOL ControlStateIsOn(MTControlState controlState) {
    return controlState == MTControlStateOn ? YES : NO;
}

@interface MADToolboxStrings : NSAttributedString

    + (instancetype)newSystemString:(NSString *)string;
    + (instancetype)newBoldSystemString:(NSString *)string;

@end

@implementation MADToolboxStrings

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

+ (instancetype)newSizeWidthForValue:(NSNumber *)value {
    NSString *width = NSLocalizedString(DialogWidth, DialogWidth);
    NSString *stringValue;
    if (value == nil) {
        stringValue = DialogSpace;
    } else {
        NSString *pointsFormat = NSLocalizedString(FormatPoints, CommentPoints);
        stringValue = [[NSString alloc] initWithFormat:pointsFormat, value.floatValue];
    }
    id newSize = [MADToolboxStrings newStringForSubject:width value:stringValue];
    return newSize;
}

+ (instancetype)newSizeHeightForValue:(NSNumber *)value {
    NSString *height = NSLocalizedString(DialogHeight, DialogHeight);
    NSString *stringValue;
    if (value == nil) {
        stringValue = DialogSpace;
    } else {
        NSString *pointsFormat = NSLocalizedString(FormatPoints, CommentPoints);
        stringValue = [[NSString alloc] initWithFormat:pointsFormat, value.floatValue];
    }
    id newSize = [MADToolboxStrings newStringForSubject:height value:stringValue];
    return newSize;
}

+ (instancetype)newMarginTopForValue:(NSNumber *)value {
    NSString *top = NSLocalizedString(DialogTop, DialogTop);
    NSString *stringValue;
    if (value == nil) {
        stringValue = DialogSpace;
    } else {
        NSString *pointsFormat = NSLocalizedString(FormatPoints, CommentPoints);
        stringValue = [[NSString alloc] initWithFormat:pointsFormat, value.floatValue];
    }
    id newMargin = [MADToolboxStrings newStringForSubject:top value:stringValue];
    return newMargin;
}

+ (instancetype)newMarginBottomForValue:(NSNumber *)value {
    NSString *bottom = NSLocalizedString(DialogBottom, DialogBottom);
    NSString *stringValue;
    if (value == nil) {
        stringValue = DialogSpace;
    } else {
        NSString *pointsFormat = NSLocalizedString(FormatPoints, CommentPoints);
        stringValue = [[NSString alloc] initWithFormat:pointsFormat, value.floatValue];
    }
    id newMargin = [MADToolboxStrings newStringForSubject:bottom value:stringValue];
    return newMargin;
}

+ (instancetype)newMarginLeftForValue:(NSNumber *)value {
    NSString *left = NSLocalizedString(DialogLeft, DialogLeft);
    NSString *stringValue;
    if (value == nil) {
        stringValue = DialogSpace;
    } else {
        NSString *pointsFormat = NSLocalizedString(FormatPoints, CommentPoints);
        stringValue = [[NSString alloc] initWithFormat:pointsFormat, value.floatValue];
    }
    id newMargin = [MADToolboxStrings newStringForSubject:left value:stringValue];
    return newMargin;
}

+ (instancetype)newMarginRightForValue:(NSNumber *)value {
    NSString *right = NSLocalizedString(DialogRight, DialogRight);
    NSString *stringValue;
    if (value == nil) {
        stringValue = DialogSpace;
    } else {
        NSString *pointsFormat = NSLocalizedString(FormatPoints, CommentPoints);
        stringValue = [[NSString alloc] initWithFormat:pointsFormat, value.floatValue];
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

    @property (nonatomic, strong) NSSet *userSelectedObjectIds;

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
                    
                    [[(UIButton *)strongControl2 titleLabel] setTextColor:titleColor];
                }
            }
            
        }];
        
    });
    
    
}

- (void)setSelectedDocumentObjects:(NSSet *)objectIds {
    [self setUserSelectedObjectIds:objectIds];
    [self updateDisplay];

}

- (void)updateDisplay {
    if (self.isViewLoaded) {
        
        if (self.userSelectedObjectIds.count == 0) {
            
            self.buttonItalic.enabled = NO;
            self.buttonBold.enabled = NO;
            self.buttonStrike.enabled = NO;
            self.buttonUnderline.enabled = NO;
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
            
            self.buttonBold.selected = NO;
            self.buttonBold.highlighted = NO;
            
            self.buttonItalic.selected = NO;
            self.buttonItalic.highlighted = NO;
            
            self.buttonStrike.selected = NO;
            self.buttonStrike.highlighted = NO;
            
            self.buttonUnderline.selected = NO;
            self.buttonUnderline.highlighted = NO;
            
            self.segmentedControlHorizontalAlignment.selected = NO;
            self.segmentedControlHorizontalAlignment.highlighted = NO;
            
            self.segmentedControlHorizontalAlignment.selectedSegmentIndex = UISegmentedControlNoSegment;
            self.segmentedControlHorizontalAlignment.userInteractionEnabled = NO;
            
            self.segmentedControlVerticalAlignment.selected = NO;
            self.segmentedControlVerticalAlignment.highlighted = NO;
            
            self.segmentedControlVerticalAlignment.selectedSegmentIndex = UISegmentedControlNoSegment;
            self.segmentedControlVerticalAlignment.userInteractionEnabled = NO;
            
            self.fontLabelTableViewCell.userInteractionEnabled = NO;
            self.stepperFontSize.userInteractionEnabled = NO;
            
            NSArray *steppers = self.steppers;
            for (UIStepper *stepper in steppers) {
                stepper.userInteractionEnabled = NO;
            }
            
            NSAttributedString *labelSizeHeightAttributedText = [MADToolboxStrings newSizeHeightForValue: nil];
            self.labelSizeHeight.attributedText = labelSizeHeightAttributedText;
            
            NSAttributedString *labelSizeWidthAttributedText = [MADToolboxStrings newSizeWidthForValue: nil];
            self.labelSizeWidth.attributedText = labelSizeWidthAttributedText;
            
            NSAttributedString *labelMarginTopAttributedText = [MADToolboxStrings newMarginTopForValue: nil];
            self.labelMarginTop.attributedText = labelMarginTopAttributedText;
            
            NSAttributedString *labelMarginBottomAttributedText = [MADToolboxStrings newMarginBottomForValue: nil];
            self.labelMarginBottom.attributedText = labelMarginBottomAttributedText;
            
            NSAttributedString *labelMarginLeftAttributedText = [MADToolboxStrings newMarginLeftForValue: nil];
            self.labelMarginLeft.attributedText = labelMarginLeftAttributedText;

            NSAttributedString *labelMarginRightAttributedText = [MADToolboxStrings newMarginRightForValue: nil];
            self.labelMarginRight.attributedText = labelMarginRightAttributedText;
            
            NSAttributedString *labelPaddingTopAttributedText = [MADToolboxStrings newMarginTopForValue: nil];
            self.labelPaddingTop.attributedText = labelPaddingTopAttributedText;
            
            NSAttributedString *labelPaddingBottomAttributedText = [MADToolboxStrings newMarginBottomForValue: nil];
            self.labelPaddingBottom.attributedText = labelPaddingBottomAttributedText;
            
            NSAttributedString *labelPaddingLeftAttributedText = [MADToolboxStrings newMarginLeftForValue: nil];
            self.labelPaddingLeft.attributedText = labelPaddingLeftAttributedText;
            
            NSAttributedString *labelPaddingRightAttributedText = [MADToolboxStrings newMarginRightForValue: nil];
            self.labelPaddingRight.attributedText = labelPaddingRightAttributedText;
            
        } else {
            
            NSArray *steppers = self.steppers;
            for (UIStepper *stepper in steppers) {
                [stepper setUserInteractionEnabled:YES];
            }
            
            self.buttonItalic.enabled = YES;
            self.buttonBold.enabled = YES;
            self.buttonStrike.enabled = YES;
            self.buttonUnderline.enabled = YES;
            
            self.controlStateBold = MTControlStateOn;
            self.controlStateItalic = MTControlStateOn;
            self.controlStateStrike = MTControlStateOn;
            self.controlStateUnderline = MTControlStateOn;
            
            NSString *fontDisplayName = nil;
            
            NSNumber *marginTopHolder = @(CGFLOAT_MIN), *marginBottomHolder = @(CGFLOAT_MIN), *marginLeftHolder = @(CGFLOAT_MIN), *marginRightHolder = @(CGFLOAT_MIN);
            NSNumber *paddingTopHolder = @(CGFLOAT_MIN), *paddingBottomHolder = @(CGFLOAT_MIN), *paddingLeftHolder = @(CGFLOAT_MIN), *paddingRightHolder = @(CGFLOAT_MIN);
            NSNumber *verticalAlignmentHolder = @(-1), *horizontalAlignmentHolder = @(-1);
            NSNumber *sizeWidthHolder = @(CGFLOAT_MIN), *sizeHeightHolder = @(CGFLOAT_MIN);
            
            CGFloat fontSizeHolder = [MADFont defaultSize];
            
            NSInteger numberOfMarginTop = 0, numberOfMarginBottom = 0, numberOfMarginLeft = 0, numberOfMarginRight = 0;
            NSInteger numberOfPaddingTop = 0, numberOfPaddingBottom = 0, numberOfPaddingLeft = 0, numberOfPaddingRight = 0;
            NSInteger numberOfHorazontalAlignments = 0, numberOfVerticalAlignments = 0;
            NSInteger numberOfSizeWidths = 0, numberOfSizeHeights = 0;
            
            NSInteger numberFonts = 0;
            NSInteger numberBold = 0, numberItalic = 0, numberStrike = 0, numberUnderline = 0;
            NSInteger numberNotBold = 0, numberNotItalic = 0, numberNotStrike = 0, numberNotUnderline = 0;
            
            for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
                RptqDocumentObject *documentObject = [self.document.managedObjectContext objectWithID:objectId];
                
                if (documentObject != nil) {
                    
                    if (![documentObject.fontname isEqualToString:fontDisplayName]) {
                        fontDisplayName = documentObject.fontname;
                        fontSizeHolder = documentObject.fontsize.floatValue;
                        numberFonts++;
                    }
                    
                    if (![documentObject.marginTop isEqualToNumber:marginTopHolder] ) {
                        marginTopHolder = documentObject.marginTop;
                        numberOfMarginTop++;
                    }
                    
                    if (![documentObject.marginBottom isEqualToNumber:marginBottomHolder] ) {
                        marginBottomHolder = documentObject.marginBottom;
                        numberOfMarginBottom++;
                    }
                    
                    if (![documentObject.marginLeft isEqualToNumber:marginLeftHolder] ) {
                        marginLeftHolder = documentObject.marginLeft;
                        numberOfMarginLeft++;
                    }
                    
                    if (![documentObject.marginRight isEqualToNumber:marginRightHolder] ) {
                        marginRightHolder = documentObject.marginRight;
                        numberOfMarginRight++;
                    }
                    
                    if (![documentObject.paddingTop isEqualToNumber:paddingTopHolder] ) {
                        paddingTopHolder = documentObject.paddingTop;
                        numberOfPaddingTop++;
                    }
                    
                    if (![documentObject.paddingBottom isEqualToNumber:paddingBottomHolder] ) {
                        paddingBottomHolder = documentObject.paddingBottom;
                        numberOfPaddingBottom++;
                    }
                    
                    if (![documentObject.paddingLeft isEqualToNumber:paddingLeftHolder] ) {
                        paddingLeftHolder = documentObject.paddingLeft;
                        numberOfPaddingLeft++;
                    }
                    
                    if (![documentObject.paddingRight isEqualToNumber:paddingRightHolder] ) {
                        paddingRightHolder = documentObject.paddingRight;
                        numberOfPaddingRight++;
                    }
                    
                    if (![documentObject.sizewidth isEqualToNumber:sizeWidthHolder] ) {
                        sizeWidthHolder = documentObject.sizewidth;
                        numberOfSizeWidths++;
                    }
                    
                    if (![documentObject.sizeheight isEqualToNumber:sizeHeightHolder] ) {
                        sizeHeightHolder = documentObject.sizeheight;
                        numberOfSizeHeights++;
                    }
                    
                    if (![documentObject.verticalAlignment isEqualToNumber:verticalAlignmentHolder] ) {
                        verticalAlignmentHolder = documentObject.verticalAlignment;
                        numberOfVerticalAlignments++;
                    }
                    if (![documentObject.horizontalAlignment isEqualToNumber:horizontalAlignmentHolder] ) {
                        horizontalAlignmentHolder = documentObject.horizontalAlignment;
                        numberOfHorazontalAlignments++;
                    }
                    
                    documentObject.bold.boolValue ? numberBold++ : numberNotBold++;
                    documentObject.underline.boolValue ? numberUnderline++ : numberNotUnderline++;
                    documentObject.strike.boolValue ? numberStrike++ : numberNotStrike++;
                    documentObject.italic.boolValue ? numberItalic++ : numberNotItalic++;
                    
                }
                
            }
            
            [self.segmentedControlHorizontalAlignment setSelectedSegmentIndex:horizontalAlignmentHolder.integerValue];
            [self.segmentedControlVerticalAlignment setSelectedSegmentIndex:verticalAlignmentHolder.integerValue];
                        
            NSNumber *displayNumber = numberOfMarginTop == 1 ? marginTopHolder : nil;
            NSAttributedString *labelMarginTopAttributedText = [MADToolboxStrings newMarginTopForValue: displayNumber];
            self.labelMarginTop.attributedText = labelMarginTopAttributedText;
            self.stepperMarginTop.value = marginTopHolder.doubleValue;
            
            displayNumber = numberOfMarginBottom == 1 ? marginBottomHolder : nil;
            
            NSAttributedString *labelMarginBottomAttributedText = [MADToolboxStrings newMarginBottomForValue: displayNumber];
            self.labelMarginBottom.attributedText = labelMarginBottomAttributedText;
            self.stepperMarginBottom.value = marginBottomHolder.doubleValue;
            
            displayNumber = numberOfMarginLeft == 1 ? marginLeftHolder : nil;
            NSAttributedString *labelMarginLeftAttributedText = [MADToolboxStrings newMarginLeftForValue: displayNumber];
            self.labelMarginLeft.attributedText = labelMarginLeftAttributedText;
            self.stepperMarginLeft.value = marginLeftHolder.doubleValue;
            
            displayNumber = numberOfMarginRight == 1 ? marginRightHolder : nil;
            NSAttributedString *labelMarginRightAttributedText = [MADToolboxStrings newMarginRightForValue: displayNumber];
            self.labelMarginRight.attributedText = labelMarginRightAttributedText;
            self.stepperMarginRight.value = marginRightHolder.doubleValue;
            
            displayNumber = numberOfPaddingTop == 1 ? paddingTopHolder : nil;
            NSAttributedString *labelPaddingTopAttributedText = [MADToolboxStrings newMarginTopForValue: displayNumber];
            self.labelPaddingTop.attributedText = labelPaddingTopAttributedText;
            self.stepperPaddingTop.value = paddingTopHolder.doubleValue;
            
            displayNumber = numberOfPaddingBottom == 1 ? paddingBottomHolder : nil;
            NSAttributedString *labelPaddingBottomAttributedText = [MADToolboxStrings newMarginBottomForValue: displayNumber];
            self.labelPaddingBottom.attributedText = labelPaddingBottomAttributedText;
            self.stepperPaddingBottom.value = paddingBottomHolder.doubleValue;
            
            displayNumber = numberOfPaddingLeft == 1 ? paddingLeftHolder : nil;
            NSAttributedString *labelPaddingLeftAttributedText = [MADToolboxStrings newMarginLeftForValue: displayNumber];
            self.labelPaddingLeft.attributedText = labelPaddingLeftAttributedText;
            self.stepperPaddingLeft.value = paddingLeftHolder.doubleValue;
            
            displayNumber = numberOfPaddingRight == 1 ? paddingRightHolder : nil;
            NSAttributedString *labelPaddingRightAttributedText = [MADToolboxStrings newMarginRightForValue: displayNumber];
            self.labelPaddingRight.attributedText = labelPaddingRightAttributedText;
            self.stepperPaddingRight.value = paddingRightHolder.doubleValue;
            
            displayNumber = numberOfSizeHeights == 1 ? sizeHeightHolder : nil;
            NSAttributedString *labelSizeHeightAttributedText = [MADToolboxStrings newSizeHeightForValue: displayNumber];
            self.labelSizeHeight.attributedText = labelSizeHeightAttributedText;
            self.stepperSizeHeight.value = sizeHeightHolder.doubleValue;
            
            displayNumber = numberOfSizeWidths == 1 ? sizeWidthHolder : nil;
            NSAttributedString *labelSizeWidthAttributedText = [MADToolboxStrings newSizeWidthForValue: displayNumber];
            self.labelSizeWidth.attributedText = labelSizeWidthAttributedText;
            self.stepperSizeWidth.value = sizeWidthHolder.doubleValue;
            
            switch (numberFonts) {
                case 0: {
                    fontDisplayName = NSLocalizedString(@"Undefined", @"Undefined");
                    NSAttributedString *attributedText = [MADToolboxStrings newBoldSystemString:fontDisplayName];
                    self.labelFontName.attributedText = attributedText;
                    break;
                }
                case 1: {
                    NSAttributedString *displayNameBold = [MADToolboxStrings newBoldSystemString:fontDisplayName];
                    NSAttributedString *displaySizeBold = [self fontSizeStringForSizeInPoints:fontSizeHolder];
                    [self.labelFontName setAttributedText: displayNameBold];
                    [self.labelFontSize setAttributedText: displaySizeBold];
                    break;
                }
                default: {
                    fontDisplayName = NSLocalizedString(@"Ambiguous", @"Ambiguous");
                    NSAttributedString *displayNameBold = [MADToolboxStrings newBoldSystemString:fontDisplayName];
                    NSAttributedString *displaySizeBold = [MADToolboxStrings newBoldSystemString:fontDisplayName];
                    [self.labelFontName setAttributedText: displayNameBold];
                    [self.labelFontSize setAttributedText:displaySizeBold];
                    break;
                }
            }
            
            self.stepperFontSize.value = fontSizeHolder;
            
            self.controlStateBold = numberBold > 0 ? ( numberNotBold > 0 ? MTControlStateAmbiguous : MTControlStateOn) : MTControlStateOff;
            self.controlStateItalic = numberItalic > 0 ? ( numberNotItalic > 0 ? MTControlStateAmbiguous : MTControlStateOn) : MTControlStateOff;
            self.controlStateStrike = numberStrike > 0 ? ( numberNotStrike > 0 ? MTControlStateAmbiguous : MTControlStateOn) : MTControlStateOff;
            self.controlStateUnderline = numberUnderline > 0 ? ( numberNotUnderline > 0 ? MTControlStateAmbiguous : MTControlStateOn) : MTControlStateOff;
            
            MTControlState controlStateHorizontalAlignment = numberOfHorazontalAlignments > 0 ? (numberOfHorazontalAlignments == 1 ? MTControlStateOn : MTControlStateAmbiguous) : MTControlStateOff;
            MTControlState controlStateVerticalAlignment = numberOfVerticalAlignments > 0 ? (numberOfVerticalAlignments == 1 ? MTControlStateOn : MTControlStateAmbiguous) : MTControlStateOff;
            
            // FIXME: Needs ambigious state for segmented control.
            
            /*
             if (controlStateHorizontalAlignment == MTControlStateAmbiguous) {
             [self.segmentedControlHorizontalAlignment setSelectedSegmentIndex:UISegmentedControlNoSegment];
             UIColor *tentColor = [[MADColorEverydayApps newColor] colorWithAlphaComponent:0.5000f];
             self.segmentedControlHorizontalAlignment.backgroundColor = tentColor;
             } else {
             //[self.segmentedControlHorizontalAlignment setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
             self.segmentedControlHorizontalAlignment.backgroundColor = [UIColor clearColor];
             }
             if (controlStateVerticalAlignment == MTControlStateAmbiguous) {
             //UIImage *imageButtonSelected = [UIImage imageNamed:@"UIButtonSelected"];
             [self.segmentedControlVerticalAlignment setSelectedSegmentIndex:UISegmentedControlNoSegment];
             //[self.segmentedControlVerticalAlignment setBackgroundImage:[imageButtonSelected resizableImage] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
             UIColor *tentColor = [[MADColorEverydayApps newColor] colorWithAlphaComponent:0.5000f];
             self.segmentedControlVerticalAlignment.backgroundColor = tentColor;
             } else {
             //[self.segmentedControlVerticalAlignment setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
             self.segmentedControlVerticalAlignment.backgroundColor = [UIColor clearColor];
             }
             */
            
            
            [self setStateInControl:self.segmentedControlHorizontalAlignment forState:controlStateHorizontalAlignment];
            [self setStateInControl:self.segmentedControlVerticalAlignment forState:controlStateVerticalAlignment];
            
            self.fontLabelTableViewCell.userInteractionEnabled = YES;
            self.stepperFontSize.userInteractionEnabled = YES;
            self.segmentedControlHorizontalAlignment.userInteractionEnabled = YES;
            self.segmentedControlVerticalAlignment.userInteractionEnabled = YES;
            
        }
        [self setStateInControl: self.buttonBold forState: self.controlStateBold];
        [self setStateInControl: self.buttonItalic forState: self.controlStateItalic];
        [self setStateInControl: self.buttonStrike forState: self.controlStateStrike];
        [self setStateInControl: self.buttonUnderline forState: self.controlStateUnderline];
    }
}

- (NSAttributedString *)fontSizeStringForSizeInPoints:(double)points {
    
    CGFloat pointSize = self.labelFontSize.font.pointSize;
    UIFont *boldFont = [UIFont boldSystemFontOfSize:pointSize];
    UIFont *systemFont = [UIFont systemFontOfSize:pointSize];
    NSDictionary *boldAttributes = @{NSFontAttributeName : boldFont};
    NSDictionary *normalAttributes = @{NSFontAttributeName : systemFont};

    NSMutableAttributedString *localizedAttributedMessage = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"Font size", "Font size")
                                                                                                   attributes:boldAttributes];
    NSString *localizedFormatPoints = NSLocalizedString(@"%#.1f pt", @"%#.1f points");
    NSString *pointsString = [@" " stringByAppendingFormat:localizedFormatPoints, points];
    NSAttributedString *messageSuffix = [[NSAttributedString alloc] initWithString:pointsString attributes:normalAttributes];
    
    [localizedAttributedMessage appendAttributedString:messageSuffix];
    self.labelFontSize.attributedText = localizedAttributedMessage;
    return localizedAttributedMessage;
}

- (void)chooseFamilyName:(NSString *)familyName {
    CGFloat systemFontSize = [UIFont systemFontSize];
    UIFont *font = [UIFont fontWithName:familyName size:systemFontSize];
    self.labelFontName.font = font;
    self.labelFontName.text = familyName;

    MADocument *doc = self.document;
    for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
        RptqDocumentObject *documentObject = [doc.managedObjectContext objectRegisteredForID:objectId];
        documentObject.fontname = familyName;
    }
    [doc saveContext];

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
    
    MADocument *doc = self.document;
    for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
        RptqDocumentObject *documentObject = [doc.managedObjectContext objectWithID:objectId];
        NSNumber *boldWrapper = @(ControlStateIsOn(self.controlStateBold));
        documentObject.bold = boldWrapper;
    }
    [doc saveContext];
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

    MADocument *doc = self.document;
    for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
        RptqDocumentObject *documentObject = [doc.managedObjectContext objectWithID:objectId];
        NSNumber *italic = @(ControlStateIsOn(self.controlStateItalic));
        documentObject.italic = italic;
    }
    [doc saveContext];
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
    
    MADocument *doc = self.document;
    for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
        RptqDocumentObject *documentObject = [doc.managedObjectContext objectWithID:objectId];
        NSNumber *strike = @(ControlStateIsOn(self.controlStateStrike));
        documentObject.strike = strike;
    }
    [doc saveContext];
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
    
    MADocument *doc = self.document;
    for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
        RptqDocumentObject *documentObject = [doc.managedObjectContext objectWithID:objectId];
        NSNumber *underline = @(ControlStateIsOn(self.controlStateUnderline));
        documentObject.underline = underline;
    }
    [doc saveContext];
}

- (void)emptySelector:(id)whofuckingCares {
    
}

- (void)updateLabelFontSize:(double)pointSize {
    NSAttributedString *attributedString = [self fontSizeStringForSizeInPoints:pointSize];
    self.labelFontSize.attributedText = attributedString;
    NSNumber *value = [[NSNumber alloc] initWithDouble: pointSize];
    for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
        RptqDocumentObject *documentObject = [self.document.managedObjectContext objectWithID:objectId];
        documentObject.fontsize = value.copy;
        [documentObject saveContext];
    }
}

- (void)updateLabelSizeHeight:(double)height {
    NSNumber *value = [[NSNumber alloc] initWithDouble: height];
    NSAttributedString *displayHeight = [MADToolboxStrings newSizeHeightForValue:value];
    self.labelSizeHeight.attributedText = displayHeight;
    for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
        RptqDocumentObject *documentObject = [self.document.managedObjectContext objectWithID:objectId];
        documentObject.sizeheight = value.copy;
        [documentObject saveContext];
    }
}

- (void)updateLabelSizeWidth:(double)width {
    NSNumber *value = [[NSNumber alloc] initWithDouble: width];
    NSAttributedString *displayWidth = [MADToolboxStrings newSizeWidthForValue:value];
    self.labelSizeWidth.attributedText = displayWidth;
    for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
        RptqDocumentObject *documentObject = [self.document.managedObjectContext objectWithID:objectId];
        documentObject.sizewidth = value.copy;
        [documentObject saveContext];
    }
}

- (void)updateHorizontalAlignment:(NSInteger)index {
    NSNumber *value = [[NSNumber alloc] initWithInteger: index];
    [self.segmentedControlHorizontalAlignment setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
        RptqDocumentObject *documentObject = [self.document.managedObjectContext objectWithID:objectId];
        documentObject.horizontalAlignment = value.copy;
        [documentObject saveContext];
    }
}

- (void)updateVerticalAlignment:(NSInteger)index {
    NSNumber *value = [[NSNumber alloc] initWithInteger: index];
    [self.segmentedControlVerticalAlignment setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
        RptqDocumentObject *documentObject = [self.document.managedObjectContext objectWithID:objectId];
        documentObject.verticalAlignment = value.copy;
        [documentObject saveContext];
    }
}

- (void)updatePaddingTop:(double)padding {
    NSNumber *value = [[NSNumber alloc] initWithDouble: padding];
    NSAttributedString *display = [MADToolboxStrings newMarginTopForValue:value];
    self.labelPaddingTop.attributedText = display;
    for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
        RptqDocumentObject *documentObject = [self.document.managedObjectContext objectWithID:objectId];
        documentObject.paddingTop = value.copy;
        [documentObject saveContext];
    }
}

- (void)updatePaddingBottom:(double)padding {
    NSNumber *value = [[NSNumber alloc] initWithDouble: padding];
    NSAttributedString *labelPaddingBottomAttributedText = [MADToolboxStrings newMarginBottomForValue:value];
    self.labelPaddingBottom.attributedText = labelPaddingBottomAttributedText;
    for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
        RptqDocumentObject *documentObject = [self.document.managedObjectContext objectWithID:objectId];
        documentObject.paddingBottom = value.copy;
        [documentObject saveContext];
    }
}
- (void)updatePaddingLeft:(double)padding {
    NSNumber *value = [[NSNumber alloc] initWithDouble: padding];
    NSAttributedString *labelPaddingLeftAttributedText = [MADToolboxStrings newMarginLeftForValue:value];
    self.labelPaddingLeft.attributedText = labelPaddingLeftAttributedText;
    for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
        RptqDocumentObject *documentObject = [self.document.managedObjectContext objectWithID:objectId];
        documentObject.paddingLeft = value;
        [documentObject saveContext];
    }
}
- (void)updatePaddingRight:(double)padding {
    NSNumber *value = [[NSNumber alloc] initWithDouble: padding];
    NSAttributedString *labelPaddingRight = [MADToolboxStrings newMarginRightForValue:value];
    self.labelPaddingRight.attributedText = labelPaddingRight;
    for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
        RptqDocumentObject *documentObject = [self.document.managedObjectContext objectWithID:objectId];
        documentObject.paddingRight = value.copy;
        [documentObject saveContext];
    }
}

- (void)updateMarginTop:(double)margin {
    NSNumber *value = [[NSNumber alloc] initWithDouble: margin];
    NSAttributedString *display = [MADToolboxStrings newMarginTopForValue: value];
    self.labelMarginTop.attributedText = display;
    for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
        RptqDocumentObject *documentObject = [self.document.managedObjectContext objectWithID:objectId];
        documentObject.marginTop = value.copy;
        [documentObject saveContext];
    }
}
- (void)updateMarginBottom:(double)margin {
    NSNumber *value = [[NSNumber alloc] initWithDouble: margin];
    NSAttributedString *display = [MADToolboxStrings newMarginBottomForValue:value];
    self.labelMarginBottom.attributedText = display;
    for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
        RptqDocumentObject *documentObject = [self.document.managedObjectContext objectWithID:objectId];
        documentObject.marginBottom = value.copy;
        [documentObject saveContext];
    }
}
- (void)updateMarginLeft:(double)margin {
    NSNumber *value = [[NSNumber alloc] initWithDouble: margin];
    NSAttributedString *labelMarginLeftAttributedText = [MADToolboxStrings newMarginLeftForValue: value];
    self.labelMarginLeft.attributedText = labelMarginLeftAttributedText;
    for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
        RptqDocumentObject *documentObject = [self.document.managedObjectContext objectWithID:objectId];
        documentObject.marginLeft = value.copy;
        [documentObject saveContext];
    }
}
- (void)updateMarginRight:(double)margin {
    NSNumber *value = [[NSNumber alloc] initWithDouble: margin];
    NSAttributedString *labelMarginRight = [MADToolboxStrings newMarginRightForValue: value];
    self.labelMarginRight.attributedText = labelMarginRight;
    for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
        RptqDocumentObject *documentObject = [self.document.managedObjectContext objectWithID:objectId];
        documentObject.marginRight = value.copy;
        [documentObject saveContext];
    }
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

- (void)uITableViewControllerDidUpdateFontToFontWithName:(NSString *)fontName {
    [self chooseFamilyName:fontName];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:MADIdentifierStoryboardSeguePushFontPicker]) {
        
        ((MADFontSelectorViewController *)segue.destinationViewController).delegate = self;
        ((MADFontSelectorViewController *)segue.destinationViewController).clearsBackground = self.clearsBackground;
        NSString *fontname = nil;
        for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
            RptqDocumentObject *documentObject = [self.document.managedObjectContext objectWithID:objectId];
            fontname = documentObject.fontname;
            break;
        }

        [((MADFontSelectorViewController *)segue.destinationViewController) setFamilyName:fontname];
        
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
