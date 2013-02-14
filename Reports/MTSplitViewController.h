//
//  ViewController.h
//  MTSplitViewController
//
//  Created by Michael Thomason on 2/13/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MTSplitViewControllerDelegate <NSObject>
- (void)displayContentController:(UIViewController *)contentController;
@end

@interface MTSplitViewController : UIViewController

@property (nonatomic, assign) id <MTSplitViewControllerDelegate> delegate;

@end
