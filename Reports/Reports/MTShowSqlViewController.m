//
//  MUIViewControllerShowSql.m
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTShowSqlViewController.h"
#import "AppDelegate.h"
#import "MTApplicationInstance.h"
#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqQuery.h"
#import "MTDatabase.h"
#import "MTAlertView.h"
#import "MTQuery.h"
//#import "MTQueryReport.h"

@interface MTShowSqlViewController ()

@end

@implementation MTShowSqlViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    MTApplicationInstance *app = [AppDelegate app];
    MAReportDocument *reportDocument = [app activeDocument];
    MTQuery *query = [reportDocument defaultQuery];
    
    NSError *error = nil;
    NSString *sqlStatement = [query getSqlOnlyActiveFields:NO error:&error];
    if (error) {
        sqlStatement = [error localizedDescription];
    }
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
