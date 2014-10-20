//
//  MUIViewControllerShowSql.m
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTShowSqlViewController.h"
#import "AppDelegate.h"
#import "MTApplicationInstance.h"
#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqQuery.h"
#import "MTDatabase.h"
#import "MTQuery.h"

@implementation MTShowSqlViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSError *error = nil;
    NSString *sqlStatement = [self.query getSqlOnlyActiveFields:NO error:&error];
    
    if (error) {
        sqlStatement = [error localizedDescription];
    }

    if ([sqlStatement length] > 0) {

        self.textView.text = sqlStatement;

    } else {

        self.textView.text = @"";
        
        NSString *title = NSLocalizedString(@"Empty Query", @"Empty Query");
        NSString *message = NSLocalizedString(@"Add tables to the query and data fields to the designer to generate a query.",
                                              @"Add tables to the query and data fields to the designer to generate a query.");
        NSString *buttonTitle = NSLocalizedString(@"Continue", @"Continue");
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle: title
                                                                                 message: message
                                                                          preferredStyle: UIAlertControllerStyleAlert];
        UIAlertAction *actionKk = [UIAlertAction actionWithTitle: buttonTitle
                                                           style: UIAlertActionStyleDefault
                                                         handler: nil];
        [alertController addAction: actionKk];
        [self presentViewController: alertController
                           animated: YES
                         completion: nil];
        

    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action
                                      fromViewController:(UIViewController *)fromViewController
                                              withSender:(id)sender {
    
    return (UIViewController *)self.delegate;
}

- (IBAction)done:(id)sender {
    [self.delegate viewControllerDidFinish:self];
}

@end
