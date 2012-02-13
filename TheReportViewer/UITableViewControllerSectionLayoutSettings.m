//
//  UITableViewControllerSectionLayoutSettings.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewControllerSectionLayoutSettings.h"
#import "UIViewTableSectionHeaderQueryBuilder.h"

@implementation UITableViewControllerSectionLayoutSettings

@synthesize delegate = _delegate;
@synthesize labelHeight = _labelHeight;
@synthesize heightStepper = _heightStepper;
@synthesize visibilitySwitch = _visibilitySwitch;

@synthesize initalStepperValue = _initalStepperValue;
@synthesize initalSwitchValue = _initalSwitchValue;

- (void)dealloc {
    [_labelHeight release];
    [_heightStepper release];
    [_visibilitySwitch release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[self visibilitySwitch] setOn:[self initalSwitchValue]];
    [[self heightStepper] setValue:[self initalStepperValue]];

    UIViewTableSectionHeaderQueryBuilder *gradentView = [[UIViewTableSectionHeaderQueryBuilder alloc] initWithFrame:[[self tableView] frame]];
    [[self tableView] setBackgroundView: gradentView];
    [gradentView release];
    
    [[self labelHeight] setText:[NSString stringWithFormat:NSLocalizedString(@"Height: %0.1f pts", @"Something like - Height: 44 pts"), [self stepperValueNormalized]]];

}

- (void)viewDidUnload {
    [self setLabelHeight:nil];
    [self setHeightStepper:nil];
    [self setVisibilitySwitch:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[self labelHeight] setText:[NSString stringWithFormat:NSLocalizedString(@"Height: %0.1f pts", @"Something like - Height: 44 pts"), [self stepperValueNormalized]]];
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
- (IBAction)heightChanged:(id)sender {
    double stepperValue = [self stepperValueNormalized];
    [[self labelHeight] setText:[NSString stringWithFormat:NSLocalizedString(@"Height: %0.1f pts", @"Something like - Height: 44 pts"), stepperValue]];
    [[self delegate] sectionLayoutDidUpdateHeight: stepperValue];
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