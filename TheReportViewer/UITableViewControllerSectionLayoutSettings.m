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

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    UIViewTableSectionHeaderQueryBuilder *gradentView = [[UIViewTableSectionHeaderQueryBuilder alloc] initWithFrame:[[self tableView] frame]];
    [[self tableView] setBackgroundView: gradentView];
    [gradentView release];
}

- (void)viewDidUnload {
    [self setLabelHeight:nil];
    [self setHeightStepper:nil];
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
    [[self labelHeight] setText:[NSString stringWithFormat:NSLocalizedString(@"Height: %0.1f pts", @"Something like - Height: 44 pts"), [self stepperValueNormalized]]];
}

- (double)stepperValueNormalized {
    return ([[self heightStepper] value] / 2);
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath { }

- (void)dealloc {
    [_labelHeight release];
    [_heightStepper release];
    [super dealloc];
}
@end
