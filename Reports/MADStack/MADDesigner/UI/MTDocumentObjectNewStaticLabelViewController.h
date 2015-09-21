//
//  MTDocumentObjectNewStaticLabelViewController.h
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDocumentObjectNewStaticLabelViewController_h
#define Reports_MTDocumentObjectNewStaticLabelViewController_h

#import <UIKit/UIKit.h>
#import "MTUnwindProtocol.h"
#import "MADViewController.h"

extern NSString * const MTDocumentObjectNewStaticLabelViewControllerIdentifier;

@interface MTDocumentObjectNewStaticLabelViewController : MADTableViewController
    <UITableViewDelegate, UITextFieldDelegate, MTUnwindProtocol>

@property (nonatomic, weak) IBOutlet UITextField *textField;

@end

#endif
