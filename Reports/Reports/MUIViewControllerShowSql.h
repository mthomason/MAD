//
//  MUIViewControllerShowSql.h
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MUIViewController.h"
#import "UIManagedDocumentReport.h"
#import "RptqDocument+Extras.h"
#import "RptqQuery+Extras.h"

@interface MUIViewControllerShowSql : MUIViewController

@property (retain, nonatomic) IBOutlet UITextView *textView;

- (IBAction)done:(id)sender;

@end