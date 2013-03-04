//
//  MUIViewControllerShowSql.h
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTViewController.h"
#import "RptqDocument+ActiveDocument.h"

@interface MTShowSqlViewController : MTViewController

@property (retain, nonatomic) IBOutlet UITextView *textView;

- (IBAction)done:(id)sender;

@end