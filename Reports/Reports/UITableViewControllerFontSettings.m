//
//  fontSettingsTableViewController.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/5/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewControllerFontSettings.h"
#import "RptqDocumentObject+Extras.h"
#import "AppDelegate.h"
#import "MTFont.h"
#import "UIColor+Gradients.h"
#import "UIImage+Resizable.h"

@interface UITableViewControllerFontSettings()

@property (nonatomic, retain) NSSet *userSelectedObjectIds;

@property (retain, nonatomic) IBOutlet UILabel *labelPaddingTop;
@property (retain, nonatomic) IBOutlet UILabel *labelPaddingBottom;
@property (retain, nonatomic) IBOutlet UILabel *labelPaddingLeft;
@property (retain, nonatomic) IBOutlet UILabel *labelPaddingRight;

@property (retain, nonatomic) IBOutlet UILabel *labelMarginTop;
@property (retain, nonatomic) IBOutlet UILabel *labelMarginBottom;
@property (retain, nonatomic) IBOutlet UILabel *labelMarginLeft;
@property (retain, nonatomic) IBOutlet UILabel *labelMarginRight;
@property (retain, nonatomic) IBOutlet UILabel *labelSizeWidth;
@property (retain, nonatomic) IBOutlet UILabel *labelSizeHeight;

@property (retain, nonatomic) IBOutlet UIStepper *stepperPaddingTop;
@property (retain, nonatomic) IBOutlet UIStepper *stepperPaddingBottom;
@property (retain, nonatomic) IBOutlet UIStepper *stepperPaddingLeft;
@property (retain, nonatomic) IBOutlet UIStepper *stepperPaddingRight;

@property (retain, nonatomic) IBOutlet UIStepper *stepperMarginTop;
@property (retain, nonatomic) IBOutlet UIStepper *stepperMarginBottom;
@property (retain, nonatomic) IBOutlet UIStepper *stepperMarginLeft;
@property (retain, nonatomic) IBOutlet UIStepper *stepperMarginRight;

@property (retain, nonatomic) IBOutlet UIStepper *stepperSizeWidth;
@property (retain, nonatomic) IBOutlet UIStepper *stepperSizeHeight;

@property (retain, nonatomic) IBOutlet UISegmentedControl *segmentedControlHorizontalAlignment;
@property (retain, nonatomic) IBOutlet UISegmentedControl *segmentedControlVerticalAlignment;

@property (assign) MTControlState controlStateBold;
@property (assign) MTControlState controlStateItalic;
@property (assign) MTControlState controlStateStrike;
@property (assign) MTControlState controlStateUnderline;

@property (retain, nonatomic) IBOutletCollection(UIStepper) NSArray *steppers;


@end

@implementation UITableViewControllerFontSettings

@synthesize delegate;

@synthesize fontLabelTableViewCell;
@synthesize labelFontName;
@synthesize segControlFontStyle;
@synthesize labelFontSize;
@synthesize stepperFontSize;

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [[self tableView] setDelegate:self];
    UIImage *imageButton = [UIImage imageNamed:@"UIButton"];
    UIImage *imageButtonHighlighted = [UIImage imageNamed:@"UIButtonHighlighted"];
    UIImage *imageButtonSelected = [UIImage imageNamed:@"UIButtonSelected"];

    [[self buttonBold] setBackgroundImage:[imageButton resizableImage] forState:UIControlStateNormal];
    [[self buttonBold] setBackgroundImage:[imageButtonHighlighted resizableImage] forState:UIControlStateHighlighted];
    [[self buttonBold] setBackgroundImage:[imageButtonSelected resizableImage] forState:UIControlStateSelected];

    [[self buttonItalic] setBackgroundImage:[imageButton resizableImage] forState:UIControlStateNormal];
    [[self buttonItalic] setBackgroundImage:[imageButtonHighlighted resizableImage] forState:UIControlStateHighlighted];
    [[self buttonItalic] setBackgroundImage:[imageButtonSelected resizableImage] forState:UIControlStateSelected];

    [[self buttonStrike] setBackgroundImage:[imageButton resizableImage] forState:UIControlStateNormal];
    [[self buttonStrike] setBackgroundImage:[imageButtonHighlighted resizableImage] forState:UIControlStateHighlighted];
    [[self buttonStrike] setBackgroundImage:[imageButtonSelected resizableImage] forState:UIControlStateSelected];

    [[self buttonUnderline] setBackgroundImage:[imageButton resizableImage] forState:UIControlStateNormal];
    [[self buttonUnderline] setBackgroundImage:[imageButtonHighlighted resizableImage] forState:UIControlStateHighlighted];
    [[self buttonUnderline] setBackgroundImage:[imageButtonSelected resizableImage] forState:UIControlStateSelected];

    //[[self segmentedControlHorizontalAlignment] setBackgroundImage:[imageButton resizableImage] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    //[[self segmentedControlHorizontalAlignment] setBackgroundImage:[imageButtonSelected resizableImage] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    //[[self segmentedControlHorizontalAlignment] setBackgroundImage:[imageButtonSelected resizableImage] forState:UIControlStateApplication barMetrics:UIBarMetricsDefault];

    //[[self segmentedControlVerticalAlignment] setBackgroundImage:[imageButton resizableImage] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    //[[self segmentedControlVerticalAlignment] setBackgroundImage:[imageButtonSelected resizableImage] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    //[[self segmentedControlVerticalAlignment] setBackgroundImage:[imageButtonSelected resizableImage] forState:UIControlStateApplication barMetrics:UIBarMetricsDefault];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateDisplay];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)dealloc {
    [_userSelectedObjectIds release];
    [labelFontName release];
    [segControlFontStyle release];
    [fontLabelTableViewCell release];
    [labelFontSize release];
    [stepperFontSize release];
    [_buttonBold release];
    [_buttonItalic release];
    [_buttonStrike release];
    [_buttonUnderline release];
    [_segmentedControlHorizontalAlignment release];

    [_labelPaddingTop release];
    [_labelPaddingBottom release];
    [_labelPaddingLeft release];
    [_labelPaddingRight release];

    [_stepperPaddingTop release];
    [_stepperPaddingBottom release];
    [_stepperPaddingLeft release];
    [_stepperPaddingRight release];
    
    [_stepperMarginTop release];
    [_stepperMarginBottom release];
    [_stepperMarginLeft release];
    [_stepperMarginRight release];
    
    [_labelMarginTop release];
    [_labelMarginBottom release];
    [_labelMarginLeft release];
    [_labelMarginRight release];
    
    [_segmentedControlVerticalAlignment release];
    [_steppers release];
    [_stepperSizeWidth release];
    [_stepperSizeHeight release];
    
    [_labelSizeWidth release];
    [_labelSizeHeight release];
    [super dealloc];
}

#pragma mark -
#pragma mark Actions

- (void)setStateInControl:(UIControl *)control forState:(MTControlState)state {
    BOOL select, highlight;
    switch (state) {
        case MTControlStateOn:
            select = NO;
            highlight = YES;
            break;
        case MTControlStateOff:
            select = NO;
            highlight = NO;
            break;
        case MTControlStateAmbiguous:
            select = YES;
            highlight = NO;
            break;
        default:
            select = NO;
            highlight = NO;
            break;
    }
    [control setSelected:select];
    [control setHighlighted:highlight];
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queuePriorityBackground, ^{
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [control setSelected:select];
            [control setHighlighted:highlight];
        }];
    });
    
}

- (void)initalizeDocumentObjects:(NSSet *)objectIds {
    [self setUserSelectedObjectIds:objectIds];
}

- (void)setSelectedDocumentObjects:(NSSet *)objectIds {
    [self setUserSelectedObjectIds:objectIds];
    [self updateDisplay];

}

- (void)updateDisplay {
    if ([[self userSelectedObjectIds] count] == 0) {
        [[self buttonItalic] setEnabled:NO];
        [[self buttonBold] setEnabled:NO];
        [[self buttonStrike] setEnabled:NO];
        [[self buttonUnderline] setEnabled:NO];
        [self setControlStateBold: MTControlStateOff];
        [self setControlStateItalic: MTControlStateOff];
        [self setControlStateStrike: MTControlStateOff];
        [self setControlStateUnderline: MTControlStateOff];
        [[self labelFontName] setAttributedText:[self boldSystemString:NSLocalizedString(@"Nothing Selected", @"Nothing Selected")
                                                                ofSize:[[[self labelFontName] font] pointSize]]];
        [[self labelFontSize] setAttributedText:[self boldSystemString:NSLocalizedString(@"Nothing", @"Nothing")
                                                                ofSize:[[[self labelFontSize] font] pointSize]]];
        [[self buttonBold] setSelected:NO];
        [[self buttonBold] setHighlighted:NO];
        [[self buttonItalic] setSelected:NO];
        [[self buttonItalic] setHighlighted:NO];
        [[self buttonStrike] setSelected:NO];
        [[self buttonStrike] setHighlighted:NO];
        [[self buttonUnderline] setSelected:NO];
        [[self buttonUnderline] setHighlighted:NO];
        [[self segmentedControlHorizontalAlignment] setSelected:NO];
        [[self segmentedControlHorizontalAlignment] setHighlighted:NO];
        [[self segmentedControlHorizontalAlignment] setSelectedSegmentIndex:UISegmentedControlNoSegment];
        [[self segmentedControlHorizontalAlignment] setUserInteractionEnabled:NO];
        [[self segmentedControlVerticalAlignment] setSelected:NO];
        [[self segmentedControlVerticalAlignment] setHighlighted:NO];
        [[self segmentedControlVerticalAlignment] setSelectedSegmentIndex:UISegmentedControlNoSegment];
        [[self segmentedControlVerticalAlignment] setUserInteractionEnabled:NO];
        [[self fontLabelTableViewCell] setUserInteractionEnabled:NO];
        [[self stepperFontSize] setUserInteractionEnabled:NO];
        for (UIStepper *stepper in [self steppers]) {
            [stepper setUserInteractionEnabled:NO];
        }
        
        
        self.labelSizeHeight.attributedText = [self sizeHeightForValue:nil andFontSize:[[[self labelSizeHeight] font] pointSize]];
        self.labelSizeWidth.attributedText = [self sizeWidthForValue:nil andFontSize:[[[self labelSizeWidth] font] pointSize]];

        self.labelMarginTop.attributedText = [self marginTopForValue:nil andFontSize:[[[self labelMarginTop] font] pointSize]];
        self.labelMarginBottom.attributedText = [self marginBottomForValue:nil andFontSize:[[[self labelMarginBottom] font] pointSize]];
        self.labelMarginLeft.attributedText = [self marginLeftForValue:nil andFontSize:[[[self labelMarginLeft] font] pointSize]];
        self.labelMarginRight.attributedText = [self marginRightForValue:nil andFontSize:[[[self labelMarginRight] font] pointSize]];

        self.labelPaddingTop.attributedText = [self marginTopForValue:nil andFontSize:[[[self labelPaddingTop] font] pointSize]];
        self.labelPaddingBottom.attributedText = [self marginBottomForValue:nil andFontSize:[[[self labelPaddingBottom] font] pointSize]];
        self.labelPaddingLeft.attributedText = [self marginLeftForValue:nil andFontSize:[[[self labelPaddingLeft] font] pointSize]];
        self.labelPaddingRight.attributedText = [self marginRightForValue:nil andFontSize:[[[self labelPaddingRight] font] pointSize]];

        
        
    } else {
        for (UIStepper *stepper in [self steppers]) {
            [stepper setUserInteractionEnabled:YES];
        }
        
        [[self buttonItalic] setEnabled:YES];
        [[self buttonBold] setEnabled:YES];
        [[self buttonStrike] setEnabled:YES];
        [[self buttonUnderline] setEnabled:YES];
        
        [self setControlStateBold: MTControlStateOn];
        [self setControlStateItalic: MTControlStateOn];
        [self setControlStateStrike: MTControlStateOn];
        [self setControlStateUnderline: MTControlStateOn];

        NSString *fontDisplayName = nil;
        NSNumber *marginTopHolder = @(CGFLOAT_MIN), *marginBottomHolder = @(CGFLOAT_MIN), *marginLeftHolder = @(CGFLOAT_MIN), *marginRightHolder = @(CGFLOAT_MIN);
        NSNumber *paddingTopHolder = @(CGFLOAT_MIN), *paddingBottomHolder = @(CGFLOAT_MIN), *paddingLeftHolder = @(CGFLOAT_MIN), *paddingRightHolder = @(CGFLOAT_MIN);
        NSNumber *verticalAlignmentHolder = @(-1), *horizontalAlignmentHolder = @(-1);
        NSNumber *sizeWidthHolder = @(CGFLOAT_MIN), *sizeHeightHolder = @(CGFLOAT_MIN);
        
        CGFloat fontSizeHolder = [MTFont defaultSize];
        
        NSInteger numberOfMarginTop = 0, numberOfMarginBottom = 0, numberOfMarginLeft = 0, numberOfMarginRight = 0;
        NSInteger numberOfPaddingTop = 0, numberOfPaddingBottom = 0, numberOfPaddingLeft = 0, numberOfPaddingRight = 0;
        NSInteger numberOfHorazontalAlignments = 0, numberOfVerticalAlignments = 0;
        NSInteger numberOfSizeWidths = 0, numberOfSizeHeights = 0;
        
        NSInteger numberFonts = 0;
        NSInteger numberBold = 0, numberItalic = 0, numberStrike = 0, numberUnderline = 0;
        NSInteger numberNotBold = 0, numberNotItalic = 0, numberNotStrike = 0, numberNotUnderline = 0;
        
        NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
        for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
            RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:objectId fromObjectContext:managedObjectContext];

            
            if (![[documentObject fontname] isEqualToString:fontDisplayName]) {
                fontDisplayName = [documentObject fontname];
                fontSizeHolder = [[documentObject fontsize] floatValue];
                numberFonts++;
            }

            if (![[documentObject marginTop] isEqualToNumber:marginTopHolder] ) {
                marginTopHolder = [documentObject marginTop];
                numberOfMarginTop++;
            }
            if (![[documentObject marginBottom] isEqualToNumber:marginBottomHolder] ) {
                marginBottomHolder = [documentObject marginBottom];
                numberOfMarginBottom++;
            }
            if (![[documentObject marginLeft] isEqualToNumber:marginLeftHolder] ) {
                marginLeftHolder = [documentObject marginLeft];
                numberOfMarginLeft++;
            }
            if (![[documentObject marginRight] isEqualToNumber:marginRightHolder] ) {
                marginRightHolder = [documentObject marginRight];
                numberOfMarginRight++;
            }
            if (![[documentObject paddingTop] isEqualToNumber:paddingTopHolder] ) {
                paddingTopHolder = [documentObject paddingTop];
                numberOfPaddingTop++;
            }
            if (![[documentObject paddingBottom] isEqualToNumber:paddingBottomHolder] ) {
                paddingBottomHolder = [documentObject paddingBottom];
                numberOfPaddingBottom++;
            }
            if (![[documentObject paddingLeft] isEqualToNumber:paddingLeftHolder] ) {
                paddingLeftHolder = [documentObject paddingLeft];
                numberOfPaddingLeft++;
            }
            if (![[documentObject paddingRight] isEqualToNumber:paddingRightHolder] ) {
                paddingRightHolder = [documentObject paddingRight];
                numberOfPaddingRight++;
            }

            if (![[documentObject sizewidth] isEqualToNumber:sizeWidthHolder] ) {
                sizeWidthHolder = [documentObject sizewidth];
                numberOfSizeWidths++;
            }
            if (![[documentObject sizeheight] isEqualToNumber:sizeHeightHolder] ) {
                sizeHeightHolder = [documentObject sizeheight];
                numberOfSizeHeights++;
            }

            if (![[documentObject verticalAlignment] isEqualToNumber:verticalAlignmentHolder] ) {
                verticalAlignmentHolder = [documentObject verticalAlignment];
                numberOfVerticalAlignments++;
            }
            if (![[documentObject horizontalAlignment] isEqualToNumber:horizontalAlignmentHolder] ) {
                horizontalAlignmentHolder = [documentObject horizontalAlignment];
                numberOfHorazontalAlignments++;
            }
            
            [[documentObject bold] boolValue] ? numberBold++ : numberNotBold++;
            [[documentObject underline] boolValue] ? numberUnderline++ : numberNotUnderline++;
            [[documentObject strike] boolValue] ? numberStrike++ : numberNotStrike++;
            [[documentObject italic] boolValue] ? numberItalic++ : numberNotItalic++;
        }
        
        [[self segmentedControlHorizontalAlignment] setSelectedSegmentIndex:[horizontalAlignmentHolder integerValue]];
        [[self segmentedControlVerticalAlignment] setSelectedSegmentIndex:[verticalAlignmentHolder integerValue]];

        CGFloat labelSize = [[[self labelFontName] font] pointSize];

        NSNumber *displayNumber = numberOfMarginTop == 1 ? marginTopHolder : nil;
        [[self labelMarginTop] setAttributedText: [self marginTopForValue:displayNumber andFontSize:labelSize]];
        [[self stepperMarginTop] setValue:[marginTopHolder doubleValue]];

        displayNumber = numberOfMarginBottom == 1 ? marginBottomHolder : nil;
        [[self labelMarginBottom] setAttributedText: [self marginBottomForValue:displayNumber andFontSize:labelSize]];
        [[self stepperMarginBottom] setValue:[marginBottomHolder doubleValue]];
        
        displayNumber = numberOfMarginLeft == 1 ? marginLeftHolder : nil;
        [[self labelMarginLeft] setAttributedText: [self marginLeftForValue:marginLeftHolder andFontSize:labelSize]];
        [[self stepperMarginLeft] setValue:[marginLeftHolder doubleValue]];
        
        displayNumber = numberOfMarginRight == 1 ? marginRightHolder : nil;
        [[self labelMarginRight] setAttributedText: [self marginRightForValue:marginRightHolder andFontSize:labelSize]];
        [[self stepperMarginRight] setValue:[marginRightHolder doubleValue]];

        displayNumber = numberOfPaddingTop == 1 ? paddingTopHolder : nil;
        [[self labelPaddingTop] setAttributedText: [self marginTopForValue:displayNumber andFontSize:labelSize]];
        [[self stepperPaddingTop] setValue:[paddingTopHolder doubleValue]];

        displayNumber = numberOfPaddingBottom == 1 ? paddingBottomHolder : nil;
        [[self labelPaddingBottom] setAttributedText: [self marginBottomForValue:displayNumber andFontSize:labelSize]];
        [[self stepperPaddingBottom] setValue:[paddingBottomHolder doubleValue]];

        displayNumber = numberOfPaddingLeft == 1 ? paddingLeftHolder : nil;
        [[self labelPaddingLeft] setAttributedText: [self marginLeftForValue:displayNumber andFontSize:labelSize]];
        [[self stepperPaddingLeft] setValue:[paddingLeftHolder doubleValue]];

        displayNumber = numberOfPaddingRight == 1 ? paddingRightHolder : nil;
        [[self labelPaddingRight] setAttributedText: [self marginRightForValue:displayNumber andFontSize:labelSize]];
        [[self stepperPaddingRight] setValue:[paddingRightHolder doubleValue]];

        displayNumber = numberOfSizeHeights == 1 ? sizeHeightHolder : nil;
        [[self labelSizeHeight] setAttributedText:[self sizeHeightForValue:displayNumber andFontSize:labelSize]];
        [[self stepperSizeHeight] setValue:[sizeHeightHolder doubleValue]];

        displayNumber = numberOfSizeWidths == 1 ? sizeWidthHolder : nil;
        [[self labelSizeWidth] setAttributedText:[self sizeHeightForValue:displayNumber andFontSize:labelSize]];
        [[self stepperSizeWidth] setValue:[sizeWidthHolder doubleValue]];
        
        switch (numberFonts) {
            case 0:
                fontDisplayName = NSLocalizedString(@"Undefined", @"Undefined");
                [[self labelFontSize] setAttributedText:[self boldSystemString:fontDisplayName ofSize:labelSize]];
                [[self labelFontName] setAttributedText:[self boldSystemString:fontDisplayName ofSize:labelSize]];
                break;
            case 1:
                [[self labelFontName] setAttributedText: [self boldSystemString:fontDisplayName ofSize:labelSize]];
                [[self labelFontSize] setAttributedText: [self fontSizeStringForSizeInPoints:fontSizeHolder]];
                break;
            default:
                fontDisplayName = NSLocalizedString(@"Ambigious", @"Ambigious");
                [[self labelFontSize] setAttributedText:[self boldSystemString:fontDisplayName ofSize:labelSize]];
                [[self labelFontName] setAttributedText:[self boldSystemString:fontDisplayName ofSize:labelSize]];
                break;
        }
        
        [[self stepperFontSize] setValue:fontSizeHolder];

        
        self.controlStateBold = numberBold > 0 ? ( numberNotBold > 0 ? MTControlStateAmbiguous : MTControlStateOn) : MTControlStateOff;
        self.controlStateItalic = numberItalic > 0 ? ( numberNotItalic > 0 ? MTControlStateAmbiguous : MTControlStateOn) : MTControlStateOff;
        self.controlStateStrike = numberStrike > 0 ? ( numberNotStrike > 0 ? MTControlStateAmbiguous : MTControlStateOn) : MTControlStateOff;
        self.controlStateUnderline = numberUnderline > 0 ? ( numberNotUnderline > 0 ? MTControlStateAmbiguous : MTControlStateOn) : MTControlStateOff;
        
        MTControlState controlStateHorizontalAlignment = numberOfHorazontalAlignments > 0 ? (numberOfHorazontalAlignments == 1 ? MTControlStateOn : MTControlStateAmbiguous) : MTControlStateOff;
        MTControlState controlStateVerticalAlignment = numberOfVerticalAlignments > 0 ? (numberOfVerticalAlignments == 1 ? MTControlStateOn : MTControlStateAmbiguous) : MTControlStateOff;

        if (controlStateHorizontalAlignment == MTControlStateAmbiguous) {
            UIImage *imageButtonSelected = [UIImage imageNamed:@"UIButtonSelected"];
            [[self segmentedControlHorizontalAlignment] setSelectedSegmentIndex:UISegmentedControlNoSegment];
            [[self segmentedControlHorizontalAlignment] setBackgroundImage:[imageButtonSelected resizableImage] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        } else {
            [[self segmentedControlHorizontalAlignment] setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        }
        if (controlStateVerticalAlignment == MTControlStateAmbiguous) {
            UIImage *imageButtonSelected = [UIImage imageNamed:@"UIButtonSelected"];
            [[self segmentedControlVerticalAlignment] setSelectedSegmentIndex:UISegmentedControlNoSegment];
            [[self segmentedControlVerticalAlignment] setBackgroundImage:[imageButtonSelected resizableImage] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        } else {
            [[self segmentedControlVerticalAlignment] setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        }
        [self setStateInControl:[self segmentedControlHorizontalAlignment] forState:controlStateHorizontalAlignment];
        [self setStateInControl:[self segmentedControlVerticalAlignment] forState:controlStateVerticalAlignment];
        
        
        [self setStateInControl:[self buttonBold] forState:[self controlStateBold]];
        [self setStateInControl:[self buttonItalic] forState:[self controlStateItalic]];
        [self setStateInControl:[self buttonStrike] forState:[self controlStateStrike]];
        [self setStateInControl:[self buttonUnderline] forState:[self controlStateUnderline]];
        
        [[self fontLabelTableViewCell] setUserInteractionEnabled:YES];
        [[self stepperFontSize] setUserInteractionEnabled:YES];
        [[self segmentedControlHorizontalAlignment] setUserInteractionEnabled:YES];
        [[self segmentedControlVerticalAlignment] setUserInteractionEnabled:YES];

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
    NSAttributedString *normalValue = [self systemString:[@" " stringByAppendingString:value] ofSize:pointSize];
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithAttributedString:boldSubject];
    [result appendAttributedString:normalValue];
    return [result autorelease];
}

- (NSAttributedString *)fontSizeStringForSizeInPoints:(CGFloat)points {
    UIFont *boldFont = [UIFont boldSystemFontOfSize:[[labelFontSize font] pointSize]];
    UIFont *systemFont = [UIFont systemFontOfSize:[[labelFontSize font] pointSize]];
    NSDictionary *boldAttributes = @{NSFontAttributeName : boldFont};
    NSDictionary *normalAttributes = @{NSFontAttributeName : systemFont};

    NSMutableAttributedString *localizedAttributedMessage = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"Font size", "Font size")
                                                                                                   attributes:boldAttributes];
    NSString *localizedFormatPoints = NSLocalizedString(@"%#.1f pt", @"%#.1f points");
    NSString *pointsString = [@" " stringByAppendingFormat:localizedFormatPoints, points];
    NSAttributedString *messageSuffix = [[NSAttributedString alloc] initWithString:pointsString attributes:normalAttributes];
    [localizedAttributedMessage appendAttributedString:messageSuffix];
    [messageSuffix release];
    [[self labelFontSize] setAttributedText:localizedAttributedMessage];
    return [localizedAttributedMessage autorelease];
}

- (NSAttributedString *)boldSystemString:(NSString *)string ofSize:(CGFloat)fontSize {
    UIFont *boldFont = [UIFont boldSystemFontOfSize:fontSize];
    NSDictionary *boldAttributes = @{NSFontAttributeName : boldFont};
    NSMutableAttributedString *localizedAttributedMessage = [[NSMutableAttributedString alloc] initWithString:string
                                                                                                   attributes:boldAttributes];
    return [localizedAttributedMessage autorelease];
}

- (NSAttributedString *)systemString:(NSString *)string ofSize:(CGFloat)fontSize {
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    NSDictionary *boldAttributes = @{NSFontAttributeName : font};
    NSMutableAttributedString *localizedAttributedMessage = [[NSMutableAttributedString alloc] initWithString:string
                                                                                                   attributes:boldAttributes];
    return [localizedAttributedMessage autorelease];
}

- (void)chooseFont:(MTFont *)font {
    [[self labelFontName] setFont:[font font]];
    [[self labelFontName] setText:[font name]];
    [[self labelFontName] setAttributedText:[self boldSystemString:[font name] ofSize:[[[self labelFontName] font] pointSize]]];
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
        RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:objectId fromObjectContext:managedObjectContext];
        [documentObject setFontname:[font name]];
    }
    [[AppDelegate activeDocument] saveContext];
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
    [self setStateInControl:[self buttonBold] forState:[self controlStateBold]];
    
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
        RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:objectId fromObjectContext:managedObjectContext];
        BOOL boldOn = [self controlStateBold] == MTControlStateOn ? YES : NO;
        [documentObject setBold:@(boldOn)];
    }
    [[AppDelegate activeDocument] saveContext];
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
    [self setStateInControl:[self buttonItalic] forState:[self controlStateItalic]];
    
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
        RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:objectId fromObjectContext:managedObjectContext];
        BOOL italicOn = [self controlStateItalic] == MTControlStateOn ? YES : NO;
        [documentObject setItalic:@(italicOn)];
    }
    [[AppDelegate activeDocument] saveContext];
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
    [self setStateInControl:[self buttonStrike] forState:[self controlStateStrike]];
    
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
        RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:objectId fromObjectContext:managedObjectContext];
        BOOL strikeOn = [self controlStateStrike] == MTControlStateOn ? YES : NO;
        [documentObject setStrike:@(strikeOn)];
    }
    [[AppDelegate activeDocument] saveContext];
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
    [self setStateInControl:[self buttonUnderline] forState:[self controlStateUnderline]];
    
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
        RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:objectId fromObjectContext:managedObjectContext];
        BOOL underlineOn = [self controlStateUnderline] == MTControlStateOn ? YES : NO;
        [documentObject setUnderline:@(underlineOn)];
    }
    [[AppDelegate activeDocument] saveContext];
}

- (IBAction)controlValueChanged:(id)sender {
    MNSDocumentReport *activeDocument = [AppDelegate activeDocument];
    NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
    
    SEL valueChangedAction;
    id valueThatChanged = nil;
    
    if ([sender isEqual:[self stepperFontSize]]) {
        valueChangedAction = @selector(setFontsize:);
        valueThatChanged = @([[self stepperFontSize] value]);
        [[self labelFontSize] setAttributedText: [self fontSizeStringForSizeInPoints:[valueThatChanged floatValue]]];

    } else if ([sender isEqual:[self stepperSizeHeight]]) {
        valueChangedAction = @selector(setSizeheight:);
        valueThatChanged = @([[self stepperSizeHeight] value]);
        CGFloat fontSize = [[[self labelSizeHeight] font] pointSize];
        NSAttributedString *displayHeight = [self sizeHeightForValue:valueThatChanged andFontSize:fontSize];
        [[self labelSizeHeight] setAttributedText:displayHeight];

    } else if ([sender isEqual:[self stepperSizeWidth]]) {
        valueChangedAction = @selector(setSizewidth:);
        valueThatChanged = @([[self stepperSizeWidth] value]);
        CGFloat fontSize = [[[self labelSizeWidth] font] pointSize];
        NSAttributedString *displayWidth = [self sizeWidthForValue:valueThatChanged andFontSize:fontSize];
        [[self labelSizeWidth] setAttributedText:displayWidth];
        
    } else if ([sender isEqual:[self segmentedControlHorizontalAlignment]]) {
        valueChangedAction = @selector(setHorizontalAlignment:);
        MTHorizontalAlignment horizontalAlignment = [[self segmentedControlHorizontalAlignment] selectedSegmentIndex];
        valueThatChanged = @(horizontalAlignment);
        [[self segmentedControlHorizontalAlignment] setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        
    } else if ([sender isEqual:[self segmentedControlVerticalAlignment]]) {
        valueChangedAction = @selector(setVerticalAlignment:);
        MTVerticalAlignment verticalAlignment = [[self segmentedControlVerticalAlignment] selectedSegmentIndex];
        valueThatChanged = @(verticalAlignment);
        [[self segmentedControlVerticalAlignment] setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        
    } else if ([sender isEqual:[self stepperPaddingBottom]]) {
        valueChangedAction = @selector(setPaddingBottom:);
        valueThatChanged = @([[self stepperPaddingBottom] value]);
        [[self labelPaddingBottom] setAttributedText:[self marginBottomForValue:valueThatChanged andFontSize:[[[self labelPaddingBottom] font] pointSize]]];
    
    } else if ([sender isEqual:[self stepperPaddingLeft]]) {
        valueChangedAction = @selector(setPaddingLeft:);
        valueThatChanged = @([[self stepperPaddingLeft] value]);
        [[self labelPaddingLeft] setAttributedText:[self marginLeftForValue:valueThatChanged andFontSize:[[[self labelPaddingLeft] font] pointSize]]];
    
    } else if ([sender isEqual:[self stepperPaddingRight]]) {
        valueChangedAction = @selector(setPaddingRight:);
        valueThatChanged = @([[self stepperPaddingRight] value]);
        [[self labelPaddingRight] setAttributedText:[self marginRightForValue:valueThatChanged andFontSize:[[[self labelPaddingRight] font] pointSize]]];
    
    } else if ([sender isEqual:[self stepperPaddingTop]]) {
        valueChangedAction = @selector(setPaddingTop:);
        valueThatChanged = @([[self stepperPaddingTop] value]);
        [[self labelPaddingTop] setAttributedText:[self marginTopForValue:valueThatChanged andFontSize:[[[self labelPaddingTop] font] pointSize]]];
    
    } else if ([sender isEqual:[self stepperMarginBottom]]) {
        valueChangedAction = @selector(setMarginBottom:);
        valueThatChanged = @([[self stepperMarginBottom] value]);
        [[self labelMarginBottom] setAttributedText:[self marginBottomForValue:valueThatChanged andFontSize:[[[self labelMarginBottom] font] pointSize]]];
    
    } else if ([sender isEqual:[self stepperMarginTop]]) {
        valueChangedAction = @selector(setMarginTop:);
        valueThatChanged = @([[self stepperMarginTop] value]);
        [[self labelMarginTop] setAttributedText:[self marginTopForValue:valueThatChanged andFontSize:[[[self labelMarginTop] font] pointSize]]];
    
    } else if ([sender isEqual:[self stepperMarginLeft]]) {
        valueChangedAction = @selector(setMarginLeft:);
        valueThatChanged = @([[self stepperMarginLeft] value]);
        [[self labelMarginLeft] setAttributedText:[self marginLeftForValue:valueThatChanged andFontSize:[[[self labelMarginLeft] font] pointSize]]];
    
    } else if ([sender isEqual:[self stepperMarginRight]]) {
        valueChangedAction = @selector(setMarginRight:);
        valueThatChanged = @([[self stepperMarginRight] value]);
        [[self labelMarginRight] setAttributedText:[self marginRightForValue:valueThatChanged andFontSize:[[[self labelMarginRight] font] pointSize]]];
    }


    for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
        RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:objectId fromObjectContext:managedObjectContext];
        [documentObject performSelector:valueChangedAction withObject:valueThatChanged];
    }
    [activeDocument saveContext];
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[tableView cellForRowAtIndexPath:indexPath] isEqual:[self fontLabelTableViewCell]]) {
        [[self delegate] fontSettingsTableViewControllerDidSelectFontList: self];
    }
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}
/*
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.0000f;
}
*/

/*
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat result = 27.0000f;
    return result;
}
*/

/*
 - (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath { }
 */

/*
 - (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section { }
 */

/*
 
 - (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
 
 }
 */

/*
 - (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
 
 }
 */


/*
 - (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

- (void)viewDidUnload {
    [self setStepperSizeWidth:nil];
    [self setStepperSizeHeight:nil];
    [self setLabelSizeWidth:nil];
    [self setLabelSizeHeight:nil];
    [super viewDidUnload];
}
@end