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
#import <CoreData/CoreData.h>
#import <MAD/MADocument.h>
#import <MAD/RptqDocumentObject.h>
#import <MAD/RptqDocumentObject+Extras.h>
#import <MAD/NSManagedObject+Extras.h>
#import <MAD/MADFont.h>
#import <MAD/MTAlignment.h>
#import "MADControlState.h"
#import "UIViewController+UI.h"

@interface MADToolboxStyleViewController()
    <UITableViewDelegate>

@property (assign) MTControlState controlStateBold;
@property (assign) MTControlState controlStateItalic;
@property (assign) MTControlState controlStateStrike;
@property (assign) MTControlState controlStateUnderline;

@property (nonatomic, strong) NSSet *userSelectedObjectIds;

@property (nonatomic, weak) IBOutlet UITableViewCell *fontLabelTableViewCell;
@property (nonatomic, weak) IBOutlet UISegmentedControl *segControlFontStyle;
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
    
    UIColor *tintColor = [self.view tintColor];
    self.buttonBold.layer.borderColor = tintColor.CGColor;
    self.buttonBold.layer.cornerRadius = 6.6666f;
    self.buttonBold.layer.borderWidth = 1.0000f;
    
    self.buttonItalic.layer.borderColor = tintColor.CGColor;
    self.buttonItalic.layer.cornerRadius = 6.6666f;
    self.buttonItalic.layer.borderWidth = 1.0000f;
    
    self.buttonStrike.layer.borderColor = tintColor.CGColor;
    self.buttonStrike.layer.cornerRadius = 6.6666f;
    self.buttonStrike.layer.borderWidth = 1.0000f;
    
    self.buttonUnderline.layer.borderColor = tintColor.CGColor;
    self.buttonUnderline.layer.cornerRadius = 6.6666f;
    self.buttonUnderline.layer.borderWidth = 1.0000f;
    
    self.completedInitalLayout = NO;
    
    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    //self.navigationController.parentViewController.preferredContentSize = CGSizeMake(320.0000f, 280.0000f);

    self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width, self.bottomLayoutGuide.length, CGSizeZero.width);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(self.topLayoutGuide.length, CGSizeZero.width, self.bottomLayoutGuide.length, CGSizeZero.width);

    if (self.completedInitalLayout == NO) {
        [self.tableView setContentOffset: CGPointMake(CGPointZero.x, -self.topLayoutGuide.length)
                                animated: NO];
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
            backgroundColor = [self.view tintColor];
            titleColor = [UIColor whiteColor];
            break;
        case MTControlStateOff:
            select = NO;
            highlight = NO;
            backgroundColor = [UIColor clearColor];
            titleColor = [self.view tintColor];
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
            titleColor = [self.view tintColor];
            break;
    }
    
    
     [control setSelected:select];
     [control setHighlighted:highlight];
    if ([control isKindOfClass:[UIButton class]]) {
        control.backgroundColor = backgroundColor;
        [control setTintColor:titleColor];
        [[(UIButton *)control titleLabel] setTextColor:titleColor];
    }
    
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);

    __weak UIControl *weakControl = control;
    dispatch_async(queuePriorityBackground, ^{
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            [weakControl setSelected:select];
            [weakControl setHighlighted:highlight];
            
            if ([weakControl isKindOfClass:[UIButton class]]) {
                weakControl.backgroundColor = backgroundColor;
                [weakControl setTintColor:titleColor];
                [[(UIButton *)weakControl titleLabel] setTextColor:titleColor];
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
        if ([[self userSelectedObjectIds] count] == 0) {
            [self.buttonItalic setEnabled:NO];
            [self.buttonBold setEnabled:NO];
            [self.buttonStrike setEnabled:NO];
            [self.buttonUnderline setEnabled:NO];
            [self setControlStateBold: MTControlStateOff];
            [self setControlStateItalic: MTControlStateOff];
            [self setControlStateStrike: MTControlStateOff];
            [self setControlStateUnderline: MTControlStateOff];
            [self.labelFontName setAttributedText:[self boldSystemString:NSLocalizedString(@"Nothing Selected", @"Nothing Selected")
                                                                    ofSize:[[self.labelFontName font] pointSize]]];
            [[self labelFontSize] setAttributedText:[self boldSystemString:NSLocalizedString(@"Nothing", @"Nothing")
                                                                    ofSize:[[[self labelFontSize] font] pointSize]]];
            [self.buttonBold setSelected:NO];
            [self.buttonBold setHighlighted:NO];
            [self.buttonItalic setSelected:NO];
            [self.buttonItalic setHighlighted:NO];
            [self.buttonStrike setSelected:NO];
            [self.buttonStrike setHighlighted:NO];
            [self.buttonUnderline setSelected:NO];
            [self.buttonUnderline setHighlighted:NO];
            [self.segmentedControlHorizontalAlignment setSelected:NO];
            [self.segmentedControlHorizontalAlignment setHighlighted:NO];
            [self.segmentedControlHorizontalAlignment setSelectedSegmentIndex:UISegmentedControlNoSegment];
            [self.segmentedControlHorizontalAlignment setUserInteractionEnabled:NO];
            [self.segmentedControlVerticalAlignment setSelected:NO];
            [self.segmentedControlVerticalAlignment setHighlighted:NO];
            [self.segmentedControlVerticalAlignment setSelectedSegmentIndex:UISegmentedControlNoSegment];
            [self.segmentedControlVerticalAlignment setUserInteractionEnabled:NO];
            [self.fontLabelTableViewCell setUserInteractionEnabled:NO];
            [self.stepperFontSize setUserInteractionEnabled:NO];
            for (UIStepper *stepper in [self steppers]) {
                [stepper setUserInteractionEnabled:NO];
            }
            
            self.labelSizeHeight.attributedText = [self sizeHeightForValue: nil
                                                               andFontSize: self.labelSizeHeight.font.pointSize];
            self.labelSizeWidth.attributedText = [self sizeWidthForValue: nil
                                                             andFontSize: self.labelSizeWidth.font.pointSize];
            
            self.labelMarginTop.attributedText = [self marginTopForValue: nil
                                                             andFontSize: self.labelMarginTop.font.pointSize];
            
            self.labelMarginBottom.attributedText = [self marginBottomForValue: nil
                                                                   andFontSize: self.labelMarginBottom.font.pointSize];
            
            self.labelMarginLeft.attributedText = [self marginLeftForValue: nil
                                                               andFontSize: self.labelMarginLeft.font.pointSize];
            self.labelMarginRight.attributedText = [self marginRightForValue: nil
                                                                 andFontSize: self.labelMarginRight.font.pointSize];
            
            self.labelPaddingTop.attributedText = [self marginTopForValue: nil
                                                              andFontSize: self.labelPaddingTop.font.pointSize];
            self.labelPaddingBottom.attributedText = [self marginBottomForValue: nil
                                                                    andFontSize: self.labelPaddingBottom.font.pointSize];
            self.labelPaddingLeft.attributedText = [self marginLeftForValue: nil
                                                                andFontSize: self.labelPaddingLeft.font.pointSize];
            self.labelPaddingRight.attributedText = [self marginRightForValue: nil
                                                                  andFontSize: self.labelPaddingRight.font.pointSize];
            
        } else {
            
            for (UIStepper *stepper in [self steppers]) {
                [stepper setUserInteractionEnabled:YES];
            }
            
            [self.buttonItalic setEnabled:YES];
            [self.buttonBold setEnabled:YES];
            [self.buttonStrike setEnabled:YES];
            [self.buttonUnderline setEnabled:YES];
            
            [self setControlStateBold: MTControlStateOn];
            [self setControlStateItalic: MTControlStateOn];
            [self setControlStateStrike: MTControlStateOn];
            [self setControlStateUnderline: MTControlStateOn];
            
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
            
            for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
                RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID:objectId
                                                                              managedObjectContext:self.document.managedObjectContext];
                
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
            
            [self.segmentedControlHorizontalAlignment setSelectedSegmentIndex:[horizontalAlignmentHolder integerValue]];
            [self.segmentedControlVerticalAlignment setSelectedSegmentIndex:[verticalAlignmentHolder integerValue]];
            
            CGFloat labelSize = [UIFont systemFontSize];
            
            NSNumber *displayNumber = numberOfMarginTop == 1 ? marginTopHolder : nil;
            self.labelMarginTop.attributedText = [self marginTopForValue: displayNumber
                                                             andFontSize: labelSize];
            self.stepperMarginTop.value = marginTopHolder.doubleValue;
            
            displayNumber = numberOfMarginBottom == 1 ? marginBottomHolder : nil;
            self.labelMarginBottom.attributedText = [self marginBottomForValue: displayNumber
                                                                   andFontSize: labelSize];
            self.stepperMarginBottom.value = marginBottomHolder.doubleValue;
            
            displayNumber = numberOfMarginLeft == 1 ? marginLeftHolder : nil;
            self.labelMarginLeft.attributedText = [self marginLeftForValue: displayNumber
                                                               andFontSize: labelSize];
            self.stepperMarginLeft.value = marginLeftHolder.doubleValue;
            
            displayNumber = numberOfMarginRight == 1 ? marginRightHolder : nil;
            self.labelMarginRight.attributedText = [self marginRightForValue: displayNumber
                                                                 andFontSize: labelSize];
            self.stepperMarginRight.value = marginRightHolder.doubleValue;
            
            displayNumber = numberOfPaddingTop == 1 ? paddingTopHolder : nil;
            self.labelPaddingTop.attributedText = [self marginTopForValue: displayNumber
                                                              andFontSize: labelSize];
            self.stepperPaddingTop.value = paddingTopHolder.doubleValue;
            
            displayNumber = numberOfPaddingBottom == 1 ? paddingBottomHolder : nil;
            self.labelPaddingBottom.attributedText = [self marginBottomForValue: displayNumber
                                                                    andFontSize: labelSize];
            self.stepperPaddingBottom.value = paddingBottomHolder.doubleValue;
            
            displayNumber = numberOfPaddingLeft == 1 ? paddingLeftHolder : nil;
            self.labelPaddingLeft.attributedText = [self marginLeftForValue: displayNumber
                                                                andFontSize: labelSize];
            self.stepperPaddingLeft.value = paddingLeftHolder.doubleValue;
            
            displayNumber = numberOfPaddingRight == 1 ? paddingRightHolder : nil;
            self.labelPaddingRight.attributedText = [self marginRightForValue: displayNumber
                                                                  andFontSize: labelSize];
            self.stepperPaddingRight.value = paddingRightHolder.doubleValue;
            
            displayNumber = numberOfSizeHeights == 1 ? sizeHeightHolder : nil;
            self.labelSizeHeight.attributedText = [self sizeHeightForValue: displayNumber
                                                               andFontSize: labelSize];
            self.stepperSizeHeight.value = sizeHeightHolder.doubleValue;
            
            displayNumber = numberOfSizeWidths == 1 ? sizeWidthHolder : nil;
            self.labelSizeWidth.attributedText = [self sizeWidthForValue: displayNumber
                                                             andFontSize: labelSize];
            self.stepperSizeWidth.value = sizeWidthHolder.doubleValue;
            
            switch (numberFonts) {
                case 0:
                    fontDisplayName = NSLocalizedString(@"Undefined", @"Undefined");
                    [[self labelFontSize] setAttributedText:[self boldSystemString:fontDisplayName ofSize:labelSize]];
                    [self.labelFontName setAttributedText:[self boldSystemString:fontDisplayName ofSize:labelSize]];
                    break;
                case 1:
                    [self.labelFontName setAttributedText: [self boldSystemString:fontDisplayName ofSize:labelSize]];
                    [[self labelFontSize] setAttributedText: [self fontSizeStringForSizeInPoints:fontSizeHolder]];
                    break;
                default:
                    fontDisplayName = NSLocalizedString(@"Ambiguous", @"Ambiguous");
                    [[self labelFontSize] setAttributedText:[self boldSystemString:fontDisplayName ofSize:labelSize]];
                    [self.labelFontName setAttributedText:[self boldSystemString:fontDisplayName ofSize:labelSize]];
                    break;
            }
            
            [self.stepperFontSize setValue:fontSizeHolder];
            
            
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
             UIColor *tentColor = [[UIColor tintColor] colorWithAlphaComponent:0.5000f];
             self.segmentedControlHorizontalAlignment.backgroundColor = tentColor;
             } else {
             //[self.segmentedControlHorizontalAlignment setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
             self.segmentedControlHorizontalAlignment.backgroundColor = [UIColor clearColor];
             }
             if (controlStateVerticalAlignment == MTControlStateAmbiguous) {
             //UIImage *imageButtonSelected = [UIImage imageNamed:@"UIButtonSelected"];
             [self.segmentedControlVerticalAlignment setSelectedSegmentIndex:UISegmentedControlNoSegment];
             //[self.segmentedControlVerticalAlignment setBackgroundImage:[imageButtonSelected resizableImage] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
             UIColor *tentColor = [[UIColor tintColor] colorWithAlphaComponent:0.5000f];
             self.segmentedControlVerticalAlignment.backgroundColor = tentColor;
             } else {
             //[self.segmentedControlVerticalAlignment setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
             self.segmentedControlVerticalAlignment.backgroundColor = [UIColor clearColor];
             }
             */
            [self setStateInControl:self.segmentedControlHorizontalAlignment forState:controlStateHorizontalAlignment];
            [self setStateInControl:self.segmentedControlVerticalAlignment forState:controlStateVerticalAlignment];
            
            
            [self.fontLabelTableViewCell setUserInteractionEnabled:YES];
            [self.stepperFontSize setUserInteractionEnabled:YES];
            [self.segmentedControlHorizontalAlignment setUserInteractionEnabled:YES];
            [self.segmentedControlVerticalAlignment setUserInteractionEnabled:YES];
            
        }
        [self setStateInControl: self.buttonBold
                       forState: self.controlStateBold];
        [self setStateInControl: self.buttonItalic
                       forState: self.controlStateItalic];
        [self setStateInControl: self.buttonStrike
                       forState: self.controlStateStrike];
        [self setStateInControl: self.buttonUnderline
                       forState: self.controlStateUnderline];
    }
}

- (NSAttributedString *)sizeWidthForValue:(NSNumber *)value andFontSize:(CGFloat)fontSize {
    NSString *width = NSLocalizedString(@"Width", @"Width");
    NSString *stringValue;
    if (value == nil) {
        stringValue = @"--";
    } else {
        NSString *pointsFormat = NSLocalizedString(@"%#.1f pt", @"Like '5.2 points.'");
        stringValue = [NSString stringWithFormat:pointsFormat, [value floatValue]];
    }
    return [self stringForSubject:width value:stringValue andFontSize:fontSize];
}

- (NSAttributedString *)sizeHeightForValue:(NSNumber *)value andFontSize:(CGFloat)fontSize {
    NSString *width = NSLocalizedString(@"Height", @"Height");
    NSString *stringValue;
    if (value == nil) {
        stringValue = @"--";
    } else {
        NSString *pointsFormat = NSLocalizedString(@"%#.1f pt", @"Like '5.2 points.'");
        stringValue = [NSString stringWithFormat:pointsFormat, [value floatValue]];
    }
    return [self stringForSubject:width value:stringValue andFontSize:fontSize];
}

- (NSAttributedString *)marginBottomForValue:(NSNumber *)value andFontSize:(CGFloat)fontSize {
    NSString *bottom = NSLocalizedString(@"Bottom", @"Bottom");
    NSString *stringValue;
    if (value == nil) {
        stringValue = @"--";
    } else {
        NSString *pointsFormat = NSLocalizedString(@"%#.1f pt", @"Like '5.2 points.'");
        stringValue = [NSString stringWithFormat:pointsFormat, [value floatValue]];
    }
    return [self stringForSubject:bottom value:stringValue andFontSize:fontSize];
}

- (NSAttributedString *)marginTopForValue:(NSNumber *)value andFontSize:(CGFloat)fontSize {
    NSString *top = NSLocalizedString(@"Top", @"Top");
    NSString *stringValue;
    if (value == nil) {
        stringValue = @"--";
    } else {
        NSString *pointsFormat = NSLocalizedString(@"%#.1f pt", @"Like '5.2 points.'");
        stringValue = [NSString stringWithFormat:pointsFormat, [value floatValue]];
    }
    return [self stringForSubject:top value:stringValue andFontSize:fontSize];
}

- (NSAttributedString *)marginLeftForValue:(NSNumber *)value andFontSize:(CGFloat)fontSize {
    NSString *left = NSLocalizedString(@"Left", @"Left");
    NSString *stringValue;
    if (value == nil) {
        stringValue = @"--";
    } else {
        NSString *pointsFormat = NSLocalizedString(@"%#.1f pt", @"Like '5.2 points.'");
        stringValue = [NSString stringWithFormat:pointsFormat, [value floatValue]];
    }
    return [self stringForSubject:left value:stringValue andFontSize:fontSize];
}

- (NSAttributedString *)marginRightForValue:(NSNumber *)value andFontSize:(CGFloat)fontSize {
    NSString *right = NSLocalizedString(@"Right", @"Right");
    NSString *stringValue;
    if (value == nil) {
        stringValue = @"--";
    } else {
        NSString *pointsFormat = NSLocalizedString(@"%#.1f pt", @"Like '5.2 points.'");
        stringValue = [NSString stringWithFormat:pointsFormat, [value floatValue]];
    }
    return [self stringForSubject:right value:stringValue andFontSize:fontSize];
}

- (NSAttributedString *)stringForSubject:(NSString *)subject value:(NSString *)value andFontSize:(CGFloat)pointSize {
    NSAttributedString *boldSubject = [self boldSystemString:subject ofSize:pointSize];
    NSAttributedString *normalValue = [self systemString: [@" " stringByAppendingString:value]
                                                  ofSize: pointSize];
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithAttributedString:boldSubject];
    [result appendAttributedString:normalValue];
    return result;
}

- (NSAttributedString *)fontSizeStringForSizeInPoints:(CGFloat)points {
    CGFloat pointSize = [[[self labelFontSize] font] pointSize];

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
    [[self labelFontSize] setAttributedText:localizedAttributedMessage];
    return localizedAttributedMessage;
}

- (NSAttributedString *)boldSystemString:(NSString *)string ofSize:(CGFloat)fontSize {
    UIFont *boldFont = [UIFont boldSystemFontOfSize:fontSize];
    NSDictionary *boldAttributes = @{NSFontAttributeName : boldFont};
    if (string == nil) {
        string = @"";
    }
    NSMutableAttributedString *localizedAttributedMessage = [[NSMutableAttributedString alloc] initWithString:string
                                                                                                   attributes:boldAttributes];
    return localizedAttributedMessage;
}

- (NSAttributedString *)systemString:(NSString *)string ofSize:(CGFloat)fontSize {
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    NSDictionary *boldAttributes = @{NSFontAttributeName : font};
    if (string == nil) {
        string = @"";
    }
    NSMutableAttributedString *localizedAttributedMessage = [[NSMutableAttributedString alloc] initWithString:string
                                                                                                   attributes:boldAttributes];
    return localizedAttributedMessage;
}

- (void)chooseFont:(MADFont *)font {
    self.labelFontName.font = [font font];
    self.labelFontName.text = font.familyName;
    [self.labelFontName setAttributedText:[self boldSystemString: font.familyName
                                                          ofSize: self.labelFontName.font.pointSize]];

    for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
        RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: objectId
                                                                      managedObjectContext: self.document.managedObjectContext];
        [documentObject setFontname:font.familyName];
    }
    [self.document saveContext];

}

- (IBAction)toggleBold:(id)sender {

    switch ([self controlStateBold]) {
        case MTControlStateOn:
            [self setControlStateBold:MTControlStateOff];
            break;
        case MTControlStateOff:
            [self setControlStateBold:MTControlStateOn];
            break;
        case MTControlStateAmbiguous:
            [self setControlStateBold:MTControlStateOn];
            break;
        default:
            [self setControlStateBold:MTControlStateOn];
            break;
    }
    [self setStateInControl:self.buttonBold forState:[self controlStateBold]];
    
    NSManagedObjectContext *managedObjectContext = [[self.document activeDocumentModel] managedObjectContext];
    for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
        RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID:objectId managedObjectContext:managedObjectContext];
        BOOL boldOn = [self controlStateBold] == MTControlStateOn ? YES : NO;
        [documentObject setBold:@(boldOn)];
    }
    [self.document saveContext];
}

- (IBAction)toggleItalic:(id)sender {
    switch ([self controlStateItalic]) {
        case MTControlStateOn:
            [self setControlStateItalic:MTControlStateOff];
            break;
        case MTControlStateOff:
            [self setControlStateItalic:MTControlStateOn];
            break;
        case MTControlStateAmbiguous:
            [self setControlStateItalic:MTControlStateOn];
            break;
        default:
            [self setControlStateItalic:MTControlStateOn];
            break;
    }
    [self setStateInControl:self.buttonItalic forState:[self controlStateItalic]];
    
    NSManagedObjectContext *managedObjectContext = [[self.document activeDocumentModel] managedObjectContext];
    for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
        RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID:objectId managedObjectContext:managedObjectContext];
        BOOL italicOn = [self controlStateItalic] == MTControlStateOn ? YES : NO;
        [documentObject setItalic:@(italicOn)];
    }
    [self.document saveContext];
}

- (IBAction)toggleStrikeThrough:(id)sender {
    switch ([self controlStateStrike]) {
        case MTControlStateOn:
            [self setControlStateStrike:MTControlStateOff];
            break;
        case MTControlStateOff:
            [self setControlStateStrike:MTControlStateOn];
            break;
        case MTControlStateAmbiguous:
            [self setControlStateStrike:MTControlStateOn];
            break;
        default:
            [self setControlStateStrike:MTControlStateOn];
            break;
    }
    [self setStateInControl:self.buttonStrike forState:[self controlStateStrike]];
    
    NSManagedObjectContext *managedObjectContext = [[self.document activeDocumentModel] managedObjectContext];
    for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
        RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID:objectId managedObjectContext:managedObjectContext];
        BOOL strikeOn = [self controlStateStrike] == MTControlStateOn ? YES : NO;
        [documentObject setStrike:@(strikeOn)];
    }
    [self.document saveContext];
}

- (IBAction)toggleUnderline:(id)sender {
    switch ([self controlStateUnderline]) {
        case MTControlStateOn:
            [self setControlStateUnderline:MTControlStateOff];
            break;
        case MTControlStateOff:
            [self setControlStateUnderline:MTControlStateOn];
            break;
        case MTControlStateAmbiguous:
            [self setControlStateUnderline:MTControlStateOn];
            break;
        default:
            [self setControlStateUnderline:MTControlStateOn];
            break;
    }
    [self setStateInControl:self.buttonUnderline forState:[self controlStateUnderline]];
    
    NSManagedObjectContext *managedObjectContext = [[self.document activeDocumentModel] managedObjectContext];
    for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
        RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID:objectId managedObjectContext:managedObjectContext];
        BOOL underlineOn = [self controlStateUnderline] == MTControlStateOn ? YES : NO;
        [documentObject setUnderline:@(underlineOn)];
    }
    [self.document saveContext];
}

- (void)emptySelector:(id)whofuckingCares {
    
}

- (IBAction)controlValueChanged:(id)sender {
    
    if ([sender isEqual:self.stepperFontSize]) {

        NSNumber *value = @([self.stepperFontSize value]);
        self.labelFontSize.attributedText = [self fontSizeStringForSizeInPoints:value.floatValue];
        for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: objectId
                                                                          managedObjectContext: self.document.managedObjectContext];
            documentObject.fontsize = value;
            [documentObject saveContext];
        }

    } else if ([sender isEqual:[self stepperSizeHeight]]) {
        
        NSNumber *value = @(self.stepperSizeHeight.value);
        CGFloat fontSize = self.labelSizeHeight.font.pointSize;
        NSAttributedString *displayHeight = [self sizeHeightForValue:value andFontSize:fontSize];
        [self.labelSizeHeight setAttributedText:displayHeight];
        for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: objectId
                                                                          managedObjectContext: self.document.managedObjectContext];
            [documentObject setSizeheight:value];
            [documentObject saveContext];
        }

    } else if ([sender isEqual:[self stepperSizeWidth]]) {
        
        NSNumber *value = @(self.stepperSizeWidth.value);
        CGFloat fontSize = self.labelSizeWidth.font.pointSize;
        NSAttributedString *displayWidth = [self sizeWidthForValue:value andFontSize:fontSize];
        [self.labelSizeWidth setAttributedText:displayWidth];
        for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: objectId
                                                                          managedObjectContext: self.document.managedObjectContext];
            [documentObject setSizewidth:value];
            [documentObject saveContext];
        }
        
    } else if ([sender isEqual:self.segmentedControlHorizontalAlignment]) {
        
        MTHorizontalAlignment horizontalAlignment = [self.segmentedControlHorizontalAlignment selectedSegmentIndex];
        NSNumber *value = @(horizontalAlignment);
        [self.segmentedControlHorizontalAlignment setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: objectId
                                                                          managedObjectContext: self.document.managedObjectContext];
            [documentObject setHorizontalAlignment:value];
            [documentObject saveContext];
        }
        
    } else if ([sender isEqual:self.segmentedControlVerticalAlignment]) {
        
        MTVerticalAlignment verticalAlignment = [self.segmentedControlVerticalAlignment selectedSegmentIndex];
        NSNumber *value = @(verticalAlignment);
        [self.segmentedControlVerticalAlignment setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: objectId
                                                                          managedObjectContext: self.document.managedObjectContext];
            [documentObject setVerticalAlignment:value];
            [documentObject saveContext];
        }
        
    } else if ([sender isEqual:[self stepperPaddingBottom]]) {
        
        NSNumber *value = @([[self stepperPaddingBottom] value]);
        [[self labelPaddingBottom] setAttributedText:[self marginBottomForValue:value andFontSize:[[[self labelPaddingBottom] font] pointSize]]];
        for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: objectId
                                                                          managedObjectContext: self.document.managedObjectContext];
            [documentObject setPaddingBottom:value];
            [documentObject saveContext];
        }

    } else if ([sender isEqual:[self stepperPaddingLeft]]) {
        
        NSNumber *value = @([[self stepperPaddingLeft] value]);
        [self.labelPaddingLeft setAttributedText:[self marginLeftForValue:value andFontSize:[[self.labelPaddingLeft font] pointSize]]];
        for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: objectId
                                                                          managedObjectContext: self.document.managedObjectContext];
            [documentObject setPaddingLeft:value];
            [documentObject saveContext];
        }

    } else if ([sender isEqual:[self stepperPaddingRight]]) {

        NSNumber *value = @([[self stepperPaddingRight] value]);
        [self.labelPaddingRight setAttributedText:[self marginRightForValue:value andFontSize:[[self.labelPaddingRight font] pointSize]]];
        for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: objectId
                                                                          managedObjectContext: self.document.managedObjectContext];
            [documentObject setPaddingRight:value];
            [documentObject saveContext];
        }

    } else if ([sender isEqual:[self stepperPaddingTop]]) {
        
        NSNumber *value = @([[self stepperPaddingTop] value]);
        [[self labelPaddingTop] setAttributedText:[self marginTopForValue:value andFontSize: self.labelPaddingTop.font.pointSize]];
        for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: objectId
                                                                          managedObjectContext: self.document.managedObjectContext];
            [documentObject setPaddingTop:value];
            [documentObject saveContext];
        }

    } else if ([sender isEqual:[self stepperMarginBottom]]) {

        NSNumber *value = @([[self stepperMarginBottom] value]);
        [[self labelMarginBottom] setAttributedText:[self marginBottomForValue:value andFontSize: self.labelMarginBottom.font.pointSize]];
        for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: objectId
                                                                          managedObjectContext: self.document.managedObjectContext];
            [documentObject setMarginBottom:value];
            [documentObject saveContext];
        }

    } else if ([sender isEqual:[self stepperMarginTop]]) {
        
        NSNumber *value = @([[self stepperMarginTop] value]);
        [[self labelMarginTop] setAttributedText:[self marginTopForValue:value andFontSize: self.labelMarginTop.font.pointSize]];
        for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: objectId
                                                                          managedObjectContext: self.document.managedObjectContext];
            [documentObject setMarginTop:value];
            [documentObject saveContext];
        }

    } else if ([sender isEqual:[self stepperMarginLeft]]) {
        
        NSNumber *value = @([[self stepperMarginLeft] value]);
        self.labelMarginLeft.attributedText = [self marginLeftForValue:value andFontSize: self.labelMarginLeft.font.pointSize];
        for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: objectId
                                                                          managedObjectContext: self.document.managedObjectContext];
            [documentObject setMarginLeft:value];
            [documentObject saveContext];
        }

    } else if ([sender isEqual:self.stepperMarginRight]) {
        
        NSNumber *value = @(self.stepperMarginRight.value);
        self.labelMarginRight.attributedText = [self marginRightForValue: value
                                                             andFontSize: self.labelMarginRight.font.pointSize];
        for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID: objectId
                                                                          managedObjectContext: self.document.managedObjectContext];
            [documentObject setMarginRight:value];
            [documentObject saveContext];
        }

    }

}

- (void)uITableViewControllerDidUpdateFontToFontWithName:(NSString *)fontName {
    CGFloat currentPointSize = [[self.labelFontName font] pointSize];
    MADFont *font = [[MADFont alloc] initWithFamilyName:fontName andPointSize:currentPointSize];
    [self chooseFont:font];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"MADIdentifierStoryboardSeguePushFontPicker"]) {
        ((MADFontSelectorViewController *)segue.destinationViewController).delegate = self;
        ((MADFontSelectorViewController *)segue.destinationViewController).document = self.document;
        ((MADFontSelectorViewController *)segue.destinationViewController).clearsBackground = self.clearsBackground;
        NSString *fontname = nil;
        for (NSManagedObjectID *objectId in self.userSelectedObjectIds) {
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID:objectId
                                                                          managedObjectContext:self.document.managedObjectContext];
            fontname = [documentObject fontname];
            break;
        }

        MADFont *font = [MADFont fontWithFamilyName:fontname];
        
        [((MADFontSelectorViewController *)segue.destinationViewController) setSelectedFont:font];
        
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
