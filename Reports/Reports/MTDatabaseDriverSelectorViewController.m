//
//  UITableViewControllerDataSourceTypes.m
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseDriverSelectorViewController.h"

@implementation MTDatabaseDriverSelectorViewController

- (void)dealloc {
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([UIDevice isPad] == NO) {
        [[self navigationItem] setPrompt: NSLocalizedString(@"Choose a datasource.", @"Choose a datasource.")];
    }

    [self setTitle: NSLocalizedString(@"Datasource Selector", @"Datasource Selector")];
    [[self navigationItem] setLeftItemsSupplementBackButton: YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([[segue identifier] isEqualToString:MTSegueShowSetUpDatasourceMySqlIdentifier]) {

        [[segue destinationViewController] setDelegate:self];
        [(MTDatabaseDriverSelectorMySqlViewController *)[segue destinationViewController] setDatabaseType:MTSegueShowSetUpDatasourceMySqlIdentifier];

    } else if ([[segue identifier] isEqualToString:MTSegueShowSetUpDatasourceSqlServerIdentifier]) {
    
        [[segue destinationViewController] setDelegate:self];
        [(MTDatabaseDriverSelectorMySqlViewController *)[segue destinationViewController] setDatabaseType:MTSegueShowSetUpDatasourceSqlServerIdentifier];

    } else if ([[segue identifier] isEqualToString:MTSegueShowSetUpDatasourceSalesForceIdentifier]) {
    
        [[segue destinationViewController] setDelegate:self];

    }
}

- (IBAction)done:(id)sender {
    [[self delegate] viewControllerDidFinish:self];
}

- (IBAction)cancel:(id)sender {
    [[self delegate] viewControllerDidFinish:self];
}

- (void)viewControllerDidFinish:(id)sender {
    [[self delegate] viewControllerDidFinish:self];
}

- (void)viewControllerDidCancel:(id)sender {
    [[self delegate] viewControllerDidCancel:self];
}

@end