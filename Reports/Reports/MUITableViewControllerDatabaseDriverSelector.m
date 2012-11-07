//
//  UITableViewControllerDataSourceTypes.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MUITableViewControllerDatabaseDriverSelector.h"

@implementation MUITableViewControllerDatabaseDriverSelector

//@synthesize delegate = _delegate;

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self navigationItem] setPrompt: NSLocalizedString(@"Choose a datasource.", @"Choose a datasource.")];
    [self setTitle: NSLocalizedString(@"New Report", @"New Report")];
    [[self navigationItem] setLeftItemsSupplementBackButton: YES];
}


- (IBAction)done:(id)sender {
    [[self delegate] viewControllerDidFinish:self];
}

- (IBAction)cancel:(id)sender {
    [[self delegate] viewControllerDidFinish:self];
}

- (void)dealloc {
    [super dealloc];
}

@end