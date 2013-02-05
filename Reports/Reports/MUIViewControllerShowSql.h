//
//  MUIViewControllerShowSql.h
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTViewController.h"
//#import "UIManagedDocumentReport.h"
//#import "RptqDocument+Extras.h"
//#import "RptqQuery+Extras.h"
#import "RptqDocument+ActiveDocument.h"

@interface MUIViewControllerShowSql : MTViewController

@property (retain, nonatomic) IBOutlet UITextView *textView;

- (IBAction)done:(id)sender;

@end