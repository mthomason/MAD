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

@property (retain, nonatomic) IBOutlet UIStepper *stepperPaddingTop;
@property (retain, nonatomic) IBOutlet UIStepper *stepperPaddingBottom;
@property (retain, nonatomic) IBOutlet UIStepper *stepperPaddingLeft;
@property (retain, nonatomic) IBOutlet UIStepper *stepperPaddingRight;

@property (retain, nonatomic) IBOutlet UIStepper *stepperMarginTop;
@property (retain, nonatomic) IBOutlet UIStepper *stepperMarginBottom;
@property (retain, nonatomic) IBOutlet UIStepper *stepperMarginLeft;
@property (retain, nonatomic) IBOutlet UIStepper *stepperMarginRight;

@property (retain, nonatomic) IBOutlet UISegmentedControl *segmentedControlHorizontalAlignment;
@property (retain, nonatomic) IBOutlet UISegmentedControl *segmentedControlVerticalAlignment;

@property (assign) MTControlState controlStateBold;
@property (assign) MTControlState controlStateItalic;
@property (assign) MTControlState controlStateStrike;
@property (assign) MTControlState controlStateUnderline;

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
    [_labelPaddingTop release];
    [_labelMarginTop release];
    [_labelMarginBottom release];
    [_labelMarginLeft release];
    [_labelMarginRight release];
    [_segmentedControlVerticalAlignment release];
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
        [[self labelFontName] setText:NSLocalizedString(@"Nothing Selected", @"Nothing Selected")];
        [[self labelFontName] setFont:[UIFont systemFontOfSize:[[[self labelFontName] font] pointSize]]];
        [[self labelFontSize] setText:@"Nothing"];
        [[self fontLabelTableViewCell] setUserInteractionEnabled:NO];
        [[self stepperFontSize] setUserInteractionEnabled:NO];
    } else {
        
        [[self buttonItalic] setEnabled:YES];
        [[self buttonBold] setEnabled:YES];
        [[self buttonStrike] setEnabled:YES];
        [[self buttonUnderline] setEnabled:YES];
        
        [self setControlStateBold: MTControlStateOn];
        [self setControlStateItalic: MTControlStateOn];
        [self setControlStateStrike: MTControlStateOn];
        [self setControlStateUnderline: MTControlStateOn];

        NSString *fontDisplayName = nil;
        
        NSInteger numberFonts = 0;

        CGFloat aFontSize = [MTFont defaultSize];
        
        NSInteger numberBold = 0, numberItalic = 0, numberStrike = 0, numberUnderline = 0;
        NSInteger numberNotBold = 0, numberNotItalic = 0, numberNotStrike = 0, numberNotUnderline = 0;
        NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
        for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
            RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:objectId fromObjectContext:managedObjectContext];
            if (![[documentObject fontname] isEqualToString:fontDisplayName]) {
                fontDisplayName = [documentObject fontname];
                aFontSize = [[documentObject fontsize] floatValue];
                numberFonts++;
            }
            [[documentObject bold] boolValue] ? numberBold++ : numberNotBold++;
            [[documentObject underline] boolValue] ? numberUnderline++ : numberNotUnderline++;
            [[documentObject strike] boolValue] ? numberStrike++ : numberNotStrike++;
            [[documentObject italic] boolValue] ? numberItalic++ : numberNotItalic++;
        }
        CGFloat labelSize = [[[self labelFontName] font] pointSize];

        switch (numberFonts) {
            case 0:
                fontDisplayName = NSLocalizedString(@"Undefined", @"Undefined");
                aFontSize = [[[self labelFontName] font] pointSize];
                [[self labelFontSize] setText:@"Nothing"];
                [[self labelFontName] setFont:[UIFont systemFontOfSize:labelSize]];
                break;
            case 1:
                
                break;
            default:
                fontDisplayName = NSLocalizedString(@"Ambigious", @"Ambigious");
                aFontSize = [[[self labelFontName] font] pointSize];
                [[self labelFontSize] setText:[NSString stringWithFormat:@"%f", aFontSize]];
                [[self labelFontName] setFont:[UIFont systemFontOfSize:labelSize]];
                break;
        }
        
        [[self stepperFontSize] setValue:aFontSize];
        NSString *localizedMessage = NSLocalizedString(@"Size: %#.1f pt", @"Font size in points.");
        [[self labelFontSize] setText:[NSString stringWithFormat:localizedMessage, aFontSize]];
        [[self labelFontName] setText:fontDisplayName];
        
        self.controlStateBold = numberBold > 0 ? ( numberNotBold > 0 ? MTControlStateAmbiguous : MTControlStateOn) : MTControlStateOff;
        self.controlStateItalic = numberItalic > 0 ? ( numberNotItalic > 0 ? MTControlStateAmbiguous : MTControlStateOn) : MTControlStateOff;
        self.controlStateStrike = numberStrike > 0 ? ( numberNotStrike > 0 ? MTControlStateAmbiguous : MTControlStateOn) : MTControlStateOff;
        self.controlStateUnderline = numberUnderline > 0 ? ( numberNotUnderline > 0 ? MTControlStateAmbiguous : MTControlStateOn) : MTControlStateOff;
        
        [self setStateInControl:[self buttonBold] forState:[self controlStateBold]];
        [self setStateInControl:[self buttonItalic] forState:[self controlStateItalic]];
        [self setStateInControl:[self buttonStrike] forState:[self controlStateStrike]];
        [self setStateInControl:[self buttonUnderline] forState:[self controlStateUnderline]];
        
        [[self fontLabelTableViewCell] setUserInteractionEnabled:YES];
        [[self stepperFontSize] setUserInteractionEnabled:YES];

    }
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

- (IBAction)stepperFontSizeValueChanged:(id)sender {
    CGFloat stepperValue = [[self stepperFontSize] value];
    NSString *localizedMessage = NSLocalizedString(@"Size: %#.1f pt", @"Font size in points.");
    [[self labelFontSize] setText:[NSString stringWithFormat:localizedMessage, stepperValue]];
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    for (NSManagedObjectID *objectId in [self userSelectedObjectIds]) {
        RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:objectId fromObjectContext:managedObjectContext];
        [documentObject setFontsize:@(stepperValue)];
    }
    [[AppDelegate activeDocument] saveContext];
}

- (IBAction)controlValueChanged:(id)sender {
    MNSDocumentReport *activeDocument = [AppDelegate activeDocument];
    NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
    
    SEL valueChangedAction;
    id valueThatChanged;
    
    if ([sender isEqual:[self stepperFontSize]]) {
        valueChangedAction = @selector(setFontsize:);
        valueThatChanged = @([[self stepperFontSize] value]);
        NSString *localizedMessage = NSLocalizedString(@"Size: %#.1f pt", @"Font size in points.");
        [[self labelFontSize] setText:[NSString stringWithFormat:localizedMessage, [valueThatChanged floatValue]]];

    } else if ([sender isEqual:[self segmentedControlHorizontalAlignment]]) {
        valueChangedAction = @selector(setHorizontalAlignment:);
        MTHorizontalAlignment horizontalAlignment = [[self segmentedControlHorizontalAlignment] selectedSegmentIndex];
        valueThatChanged = @(horizontalAlignment);
        
    } else if ([sender isEqual:[self segmentedControlVerticalAlignment]]) {
        valueChangedAction = @selector(setVerticalAlignment:);
        MTVerticalAlignment verticalAlignment = [[self segmentedControlVerticalAlignment] selectedSegmentIndex];
        valueThatChanged = @(verticalAlignment);

    } else if ([sender isEqual:[self stepperPaddingBottom]]) {
        valueChangedAction = @selector(setPaddingBottom:);
        valueThatChanged = @([[self stepperPaddingBottom] value]);
        NSString *localizedMessage = NSLocalizedString(@"Bottom: %#.1f pt", @"Bottom margin in points.");
        [[self labelPaddingBottom] setText:[NSString stringWithFormat:localizedMessage, [valueThatChanged floatValue]]];
    
    } else if ([sender isEqual:[self stepperPaddingLeft]]) {
        valueChangedAction = @selector(setPaddingLeft:);
        valueThatChanged = @([[self stepperPaddingLeft] value]);
        NSString *localizedMessage = NSLocalizedString(@"Left: %#.1f pt", @"Left margin in points.");
        [[self labelPaddingLeft] setText:[NSString stringWithFormat:localizedMessage, [valueThatChanged floatValue]]];
    
    } else if ([sender isEqual:[self stepperPaddingRight]]) {
        valueChangedAction = @selector(setPaddingRight:);
        valueThatChanged = @([[self stepperPaddingRight] value]);
        NSString *localizedMessage = NSLocalizedString(@"Right: %#.1f pt", @"Right margin in points.");
        [[self labelPaddingRight] setText:[NSString stringWithFormat:localizedMessage, [valueThatChanged floatValue]]];
    
    } else if ([sender isEqual:[self stepperPaddingTop]]) {
        valueChangedAction = @selector(setPaddingTop:);
        valueThatChanged = @([[self stepperPaddingTop] value]);
        NSString *localizedMessage = NSLocalizedString(@"Top: %#.1f pt", @"Top margin in points.");
        [[self labelPaddingTop] setText:[NSString stringWithFormat:localizedMessage, [valueThatChanged floatValue]]];
    
    } else if ([sender isEqual:[self stepperMarginBottom]]) {
        valueChangedAction = @selector(setMarginBottom:);
        valueThatChanged = @([[self stepperMarginBottom] value]);
        NSString *localizedMessage = NSLocalizedString(@"Bottom: %#.1f pt", @"Bottom margin in points.");
        [[self labelMarginBottom] setText:[NSString stringWithFormat:localizedMessage, [valueThatChanged floatValue]]];
    
    } else if ([sender isEqual:[self stepperMarginTop]]) {
        valueChangedAction = @selector(setMarginTop:);
        valueThatChanged = @([[self stepperMarginTop] value]);
        NSString *localizedMessage = NSLocalizedString(@"Top: %#.1f pt", @"Top margin in points.");
        [[self labelMarginTop] setText:[NSString stringWithFormat:localizedMessage, [valueThatChanged floatValue]]];
    
    } else if ([sender isEqual:[self stepperMarginLeft]]) {
        valueChangedAction = @selector(setMarginLeft:);
        valueThatChanged = @([[self stepperMarginLeft] value]);
        NSString *localizedMessage = NSLocalizedString(@"Left: %#.1f pt", @"Left margin in points.");
        [[self labelMarginLeft] setText:[NSString stringWithFormat:localizedMessage, [valueThatChanged floatValue]]];
    
    } else if ([sender isEqual:[self stepperMarginRight]]) {
        valueChangedAction = @selector(setMarginRight:);
        valueThatChanged = @([[self stepperMarginRight] value]);
        NSString *localizedMessage = NSLocalizedString(@"Right: %#.1f pt", @"Right margin in points.");
        [[self labelMarginRight] setText:[NSString stringWithFormat:localizedMessage, [valueThatChanged floatValue]]];
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
    [self setButtonBold:nil];
    [self setButtonItalic:nil];
    [self setButtonStrike:nil];
    [self setButtonUnderline:nil];
    [self setSegmentedControlHorizontalAlignment:nil];
    [self setLabelPaddingTop:nil];
    [self setLabelPaddingBottom:nil];
    [self setLabelPaddingLeft:nil];
    [self setLabelPaddingRight:nil];
    [self setStepperPaddingTop:nil];
    [self setStepperPaddingBottom:nil];
    [self setStepperPaddingLeft:nil];
    [self setStepperPaddingRight:nil];
    [self setStepperMarginTop:nil];
    [self setStepperMarginBottom:nil];
    [self setStepperMarginLeft:nil];
    [self setStepperMarginRight:nil];
    [self setLabelMarginTop:nil];
    [self setLabelPaddingTop:nil];
    [self setLabelMarginTop:nil];
    [self setLabelMarginBottom:nil];
    [self setLabelMarginLeft:nil];
    [self setLabelMarginRight:nil];
    [self setSegmentedControlVerticalAlignment:nil];
    [super viewDidUnload];
}
@end