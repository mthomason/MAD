//
//  MUIViewControllerShowSql.h
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTShowSqlViewController_h
#define Reports_MTShowSqlViewController_h

#import "MTViewController.h"

@interface MTShowSqlViewController : MTViewController

@property (nonatomic, retain) IBOutlet UITextView *textView;

- (IBAction)done:(id)sender;

@end

#endif
