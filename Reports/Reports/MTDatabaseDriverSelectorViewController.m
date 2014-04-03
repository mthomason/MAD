//
//  UITableViewControllerDataSourceTypes.m
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseDriverSelectorViewController.h"
#import "MTConnectionViewController.h"
#import "UIDevice+Hack.h"
#import "Constants.h"
#import "MTDatabaseMySql.h"
#import "MTDatabaseSqlServer.h"
#import "MTDatabaseSqlite3.h"

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
    
    NSString *dbId = nil;
    if ([[segue identifier] isEqualToString:MTSegueShowSetUpDatasourceMySqlIdentifier]) {

        [[segue destinationViewController] setDelegate:self];
        dbId = [[MTDatabaseMySql identifier] retain];

    } else if ([[segue identifier] isEqualToString:MTSegueShowSetUpDatasourceSqlServerIdentifier]) {
    
        [[segue destinationViewController] setDelegate:self];
        dbId = [[MTDatabaseSqlServer identifier] retain];

    } else if ([[segue identifier] isEqualToString:MTSegueShowSetUpDatasourceSalesForceIdentifier]) {
    
        [[segue destinationViewController] setDelegate:self];
        dbId = [[MTDatabaseSqlite3 identifier] retain];

    }
    if ([[segue destinationViewController] respondsToSelector:@selector(setDatabaseType:)]) {
        [(MTConnectionViewController *)[segue destinationViewController] setDatabaseType:dbId];
    }
    [dbId release];
}

- (void)viewControllerDidFinish:(id)sender {
    [[self delegate] viewControllerDidFinish:self];
}

- (void)viewControllerDidCancel:(id)sender {
    [[self delegate] viewControllerDidCancel:self];
}

@end