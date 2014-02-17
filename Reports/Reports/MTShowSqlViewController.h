//
//  MUIViewControllerShowSql.h
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTShowSqlViewController_h
#define Reports_MTShowSqlViewController_h

#import "MTViewController.h"
#import "MTApplicationInstance.h"

@interface MTShowSqlViewController : MTViewController

@property (nonatomic, retain) IBOutlet UITextView *textView;

//@property (nonatomic, retain) MTApplicaitonInstance *applicationInstance;

- (IBAction)done:(id)sender;

@end

#endif
