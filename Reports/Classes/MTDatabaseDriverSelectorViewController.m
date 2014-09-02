//
//  UITableViewControllerDataSourceTypes.m
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDatabaseDriverSelectorViewController.h"
#import "MTConnectionViewController.h"
#import "UIDevice+Hack.h"
#import "Constants.h"
#import "MTDatabaseMySql.h"
#import "MTDatabaseSqlServer.h"
#import "MTDatabaseSqlite3.h"

NSString * const MTDatabaseDriverSelectorViewControllerDefaultPrompt = @"Select a database type.";
NSString * const MTDatabaseDriverSelectorViewControllerDefaultTitle = @"Supported Databases";

@interface MTDatabaseDriverSelectorViewController ()
    <MTViewControllerProtocol>

@end

@implementation MTDatabaseDriverSelectorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([UIDevice isPad] == NO) {
        self.navigationItem.prompt = NSLocalizedString(MTDatabaseDriverSelectorViewControllerDefaultPrompt, MTDatabaseDriverSelectorViewControllerDefaultPrompt);
    }

    self.navigationItem.title = NSLocalizedString(MTDatabaseDriverSelectorViewControllerDefaultTitle, MTDatabaseDriverSelectorViewControllerDefaultTitle);
    [self.navigationItem setLeftItemsSupplementBackButton: YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    NSString *dbId = nil;
    if ([[segue identifier] isEqualToString:MTSegueShowSetUpDatasourceMySqlIdentifier]) {

        ((MTConnectionViewController *)segue.destinationViewController).delegate = self;
        dbId = [MTDatabaseMySql identifier];

    } else if ([[segue identifier] isEqualToString:MTSegueShowSetUpDatasourceSqlServerIdentifier]) {
    
        ((MTConnectionViewController *)segue.destinationViewController).delegate = self;
        dbId = [MTDatabaseSqlServer identifier];

    } else if ([[segue identifier] isEqualToString:MTSegueShowSetUpDatasourceSalesForceIdentifier]) {
    
        ((MTConnectionViewController *)segue.destinationViewController).delegate = self;
        dbId = [MTDatabaseSqlite3 identifier];

    }
    if ([segue.destinationViewController respondsToSelector:@selector(setDatabaseType:)]) {
        [(MTConnectionViewController *)segue.destinationViewController setDatabaseType:dbId];
    }
}

- (void)viewControllerDidFinish:(id)sender {
    [self.delegate viewControllerDidFinish:self];
}

- (void)viewControllerDidCancel:(id)sender {
    [self.delegate viewControllerDidCancel:self];
}

@end
