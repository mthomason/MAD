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

#import "MADViewControllerSQL.h"

@implementation MADViewControllerSQL

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSError *error = nil;
    NSString *sqlStatement = [self.query getSqlOnlyActiveFields:NO error:&error];
    
    if (error) {
        sqlStatement = error.localizedDescription;
    }

    if (sqlStatement.length > 0) {

        self.textView.text = sqlStatement;

    } else {

        self.textView.text = @"";
        
        UIAlertController *alertController = [UIAlertController errorEmptyQuery];
        [self presentViewController: alertController
                           animated: YES
                         completion: nil];
        

    }
}

- (IBAction)done:(id)sender {
    [self.delegate viewControllerDidFinish:self];
}

@end
