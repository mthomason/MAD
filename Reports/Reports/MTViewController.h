//
//  MUIViewController.h
//  Reports
//
//  Created by Michael Thomason on 10/31/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MUIViewControllerDelegate.h"

@interface MTViewController : UIViewController

@property (assign, nonatomic) IBOutlet id <MUIViewControllerDelegate> delegate;

@end
