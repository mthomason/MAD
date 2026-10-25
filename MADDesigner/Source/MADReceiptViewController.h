//
//  UIReceiptViewController.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/21/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADReceiptViewController_h
#define MAD_Designer_MADReceiptViewController_h

#import <UIKit/UITableViewController.h>
#import <MADAPI/MADViewControllerStandardProtocol.h>

@interface MADReceiptViewController : UITableViewController

@property (nonatomic, weak) id <MADViewControllerStandardProtocol> delegate;

@end

#endif
