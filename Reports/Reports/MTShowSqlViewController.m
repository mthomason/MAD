//
//  MUIViewControllerShowSql.m
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTShowSqlViewController.h"
#import "RptqQuery+Extras.h"

@interface MTShowSqlViewController ()

@end

@implementation MTShowSqlViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    RptqQuery *query = [RptqDocument queryForActiveDocument];
    MTDatabase *databaseHandler = [MTDatabase databaseObjectForRptqDatabase:[query inDatabase]];
    NSString *sqlStatement = [databaseHandler getSqlForQuery: query onlyActiveFields: NO];
    if ([sqlStatement length] > 0) {
        [[self textView] setText:sqlStatement];
    } else {
        [[self textView] setText:@""];
        NSString *title = NSLocalizedString(@"Empty Query", @"Empty Query");
        NSString *message = NSLocalizedString(@"Add tables to the query and data fields to the designer to generate a query.", @"Add tables to the query and data fields to the designer to generate a query.");
        NSString *cancel = NSLocalizedString(@"Continue", @"Continue");
        MTAlertView *alert = [[MTAlertView alloc] initWithTitle: title
                                                        message: message
                                              cancelButtonTitle: cancel
                                               otherButtonTitle: @[]
                                                      onDismiss: ^(NSInteger buttonIndex) { }
                                                       onCancel: ^{ }];
        [alert show];
        [alert release];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (IBAction)done:(id)sender {
    [[self delegate] viewControllerDidFinish:self];
}

- (void)dealloc {
    [_textView release];
    [super dealloc];
}

@end