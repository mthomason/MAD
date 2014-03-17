//
//  MUIViewController.h
//  Reports
//
//  Created by Michael Thomason on 10/31/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTViewController_h
#define Reports_MTViewController_h

#import <UIKit/UIKit.h>
#import "MUIViewControllerDelegate.h"

@interface MTViewController : UIViewController

@property (assign, nonatomic) IBOutlet id <MTViewControllerProtocol> delegate;

@end

#endif
