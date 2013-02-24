//
//  MUIViewControllerDelegate.h
//  Reports
//
//  Created by Michael Thomason on 11/1/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MUIViewControllerDelegate
@optional
- (void)viewControllerDidFinish:(id)sender;
- (void)viewControllerDidCancel:(id)sender;
- (void)viewControllerDidFinish:(id)sender animated:(BOOL)animated;
- (void)viewControllerDidCancel:(id)sender animated:(BOOL)animated;
@end