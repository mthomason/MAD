//
//  MTTableViewControllerAbout.h
//  MAD
//
//  Created by Michael Thomason on 8/20/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTTableViewControllerAbout_h
#define Reports_MTTableViewControllerAbout_h

#import <UIKit/UITableViewController.h>
#import <CoreText/CoreText.h>
#import <MAD/MADConstants.h>
#import "MUIViewControllerDelegate.h"

@interface MADAboutTableViewController : UITableViewController

@property (nonatomic, weak) IBOutlet id <MTViewControllerProtocol, UITableViewDelegate> delegate;

+ (instancetype)AboutTableViewController;

- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;

@end

#endif
