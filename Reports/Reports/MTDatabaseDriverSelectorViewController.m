//
//  UITableViewControllerDataSourceTypes.m
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseDriverSelectorViewController.h"
#import "MTDatabaseDriverSelectorMySqlViewController.h"
#import "UIDevice+Hack.h"
#import "Constants.h"

@implementation MTDatabaseDriverSelectorViewController

- (void)dealloc {
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([UIDevice isPad] == NO) {
        [[self navigationItem] setPrompt: NSLocalizedString(@"Choose a datasource.", @"Choose a datasource.")];
    }

    [self setTitle: NSLocalizedString(@"Type", @"Type")];
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

- (void)viewControllerDidFinish:(id)sender {
    [[self delegate] viewControllerDidFinish:self];
}

- (void)viewControllerDidCancel:(id)sender {
    [[self delegate] viewControllerDidCancel:self];
}

@end