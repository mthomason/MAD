//
//  MUIViewControllerShowSql.h
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTShowSqlViewController_h
#define Reports_MTShowSqlViewController_h

#import <UIKit/UIViewController.h>

@protocol MADViewControllerStandardProtocol;

@class MADocument, MADQuery, UITextView;

@interface MADViewControllerSQL : UIViewController

    @property (nonatomic, weak) id <MADViewControllerStandardProtocol> delegate;
    @property (nonatomic, weak) MADocument *document;
    @property (nonatomic, weak) IBOutlet UITextView *textView;

    - (IBAction)done:(id)sender;

@end

#endif
