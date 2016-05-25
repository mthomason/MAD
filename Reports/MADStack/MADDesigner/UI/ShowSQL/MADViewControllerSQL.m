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

#import <UIKit/UITextView.h>
#import <MADCocoaExtensions/UIAlertController+Constructors.h>

#import <MAD/MADocument.h>
#import <MAD/MTQuery.h>
#import <MAD/MTQueryFull.h>

#import "MUIViewControllerDelegate.h"

@implementation MADViewControllerSQL

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    MADocument *doc = self.document;
    NSError *error = nil;
    NSString *sqlStatement = [doc.mainQuery getSqlOnlyActiveFields:NO managedObjectContext:doc.managedObjectContext error:&error];
    
    if (error) {
        sqlStatement = error.localizedDescription;
    }

    if (sqlStatement.length > 0) {

        self.textView.text = sqlStatement;

    } else {

        self.textView.text = @"";
        
        UIAlertController *alertController = [UIAlertController newAlertControllerErrorEmptyQuery];
        [self presentViewController: alertController
                           animated: YES
                         completion: nil];
        

    }
}

- (IBAction)done:(id)sender {
    [self.delegate viewControllerDidFinish:self];
}

@end
