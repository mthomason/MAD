//
//  MUIViewControllerShowSql.h
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTShowSqlViewController_h
#define Reports_MTShowSqlViewController_h

#import "MUIViewControllerDelegate.h"

@class  MTQuery;

@interface MADViewControllerSQL : UIViewController

@property (nonatomic, weak) id <MTViewControllerProtocol> delegate;
@property (nonatomic, weak) MTQuery *query;
@property (nonatomic, weak) IBOutlet UITextView *textView;

- (IBAction)done:(id)sender;

@end

#endif
