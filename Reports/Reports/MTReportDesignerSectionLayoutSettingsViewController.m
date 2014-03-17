//
//  UITableViewControllerSectionLayoutSettings.m
//  Reports
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTReportDesignerSectionLayoutSettingsViewController.h"
#import "UIColor+EverydayApps.h"

NSString * const MTReportDesignerSectionLayoutSettingsViewControllerIdentifier = @"MTReportDesignerSectionLayoutSettingsViewControllerIdentifier";

@interface MTReportDesignerSectionLayoutSettingsViewController ()

@property (nonatomic, retain) IBOutlet UILabel *labelHeight;
@property (nonatomic, retain) IBOutlet UILabel *labelNumberOfRows;

@property (nonatomic, retain) IBOutlet UIStepper *heightStepper;
@property (nonatomic, retain) IBOutlet UIStepper *rowsStepper;

@property (nonatomic, retain) IBOutlet UISwitch *visibilitySwitch;

@end

@implementation MTReportDesignerSectionLayoutSettingsViewController

- (void)dealloc {
    [_labelHeight release];
    [_labelNumberOfRows release];
    [_heightStepper release];
    [_rowsStepper release];
    [_visibilitySwitch release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[[self navigationController] navigationBar] setBarStyle:UIBarStyleBlackOpaque];
    UIColor *tintColor = [UIColor tintColorRed];
    [[[[[self navigationController] navigationBar] topItem] rightBarButtonItem] setTintColor:tintColor];
    [self updateDisplay];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateDisplay];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)updateDisplay {

    [[self visibilitySwitch] setOn:[self initalSwitchValue]];
    [[self heightStepper] setValue:[self initalStepperValue] * 2];
    [[self rowsStepper] setValue:[self initalNumberOfRows]];
    
    [self setNumberOfRowsLabel:[self initalNumberOfRows]];
    [self setHeighLabel:[self initalStepperValue]];
    
}

- (void)setHeighLabel:(double)height {
    NSString *localizedFormatString = NSLocalizedString(@"Height: %0.1f pts", @"Something like - Height: 44 pts");
    NSString *localizedHeight = [NSString stringWithFormat:localizedFormatString, height];
    [[self labelHeight] setText:localizedHeight];
}

- (void)setNumberOfRowsLabel:(NSUInteger)numberOfRows {
    NSString *localizedNumberOfRows = [NSNumberFormatter localizedStringFromNumber: @(numberOfRows)
                                                                                  numberStyle: NSNumberFormatterSpellOutStyle];
    NSString *localizedFormatString = NSLocalizedString(@"Rows: %@", @"Something like - Rows: two");
    NSString *localizedHeight = [NSString stringWithFormat:localizedFormatString, localizedNumberOfRows];
    [[self labelNumberOfRows] setText:localizedHeight];
}

- (IBAction)heightChanged:(id)sender {
    double stepperValue = [self stepperValueNormalized];
    [self setHeighLabel: stepperValue];
    [[self delegate] sectionLayoutDidUpdateHeight: stepperValue];
}

- (IBAction)numberOfRowsChanged:(id)sender {
    UIStepper *rowStepper = sender;
    NSUInteger numberOfRows = [rowStepper value];
    [self setNumberOfRowsLabel:numberOfRows];
    [[self delegate] sectionLayoutDidUpdateNumberOfRows:numberOfRows];
}

- (IBAction)visibilityChanged:(id)sender {
    [[self delegate] sectionLayoutDidUpdateVisibility:[[self visibilitySwitch] isOn]];
}

#pragma mark - Helpers

- (double)stepperValueNormalized {
    return ([[self heightStepper] value] / 2);
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath { }

@end
