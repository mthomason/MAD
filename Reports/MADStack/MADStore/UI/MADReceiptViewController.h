//
//  UIReceiptViewController.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/21/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADReceiptViewController_h
#define MAD_Designer_MADReceiptViewController_h

#import <UIKit/UITableViewController.h>
#import "MUIViewControllerDelegate.h"

@interface MADReceiptViewController : UITableViewController

    @property (nonatomic, weak) id <MTViewControllerProtocol> delegate;

@end

#endif
