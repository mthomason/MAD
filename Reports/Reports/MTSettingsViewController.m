//
//  UITableViewControllerSettings.m
//  Reports
//
//  Created by Michael Thomason on 1/8/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTSettingsViewController.h"


@implementation MTSettingsViewController

- (void)dealloc {
    [_tableCellPrint release];
    [_tableCellExport release];
    [_tableCellFind release];
    [_tableCellReportSetup release];
    [_tableCellRuler release];
    [_tableCellFind release];
    [_tableCellSettings release];
    [_tableCellHelp release];
    [_tableCellStore release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {

    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setClearsSelectionOnViewWillAppear: YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [[self delegate] viewControllerDidFinish:self];
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath { }

@end