//
//  MTDocumentObjectNewStaticLabelViewController.h
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDocumentObjectNewStaticLabelViewController_h
#define Reports_MTDocumentObjectNewStaticLabelViewController_h

#import <UIKit/UITableViewController.h>
#import "MADUnwindProtocol.h"
#import <UIKit/UITableView.h>
#import <UIKit/UITextField.h>

extern NSString * const MTDocumentObjectNewStaticLabelViewControllerIdentifier;

@interface MTDocumentObjectNewStaticLabelViewController : UITableViewController
    <UITableViewDelegate,
        UITextFieldDelegate,
        MADUnwindProtocol>

    @property (nonatomic, weak) IBOutlet UITextField *textField;

@end

#endif
