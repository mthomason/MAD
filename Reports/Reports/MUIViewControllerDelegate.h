//
//  MUIViewControllerDelegate.h
//  Reports
//
//  Created by Michael Thomason on 11/1/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MUIViewControllerProtocol_h
#define Reports_MUIViewControllerProtocol_h

#import <Foundation/Foundation.h>

@protocol MTViewControllerProtocol
@optional
- (void)viewControllerDidFinish:(id)sender;
- (void)viewControllerDidCancel:(id)sender;
- (void)viewControllerDidFinish:(id)sender animated:(BOOL)animated;
- (void)viewControllerDidCancel:(id)sender animated:(BOOL)animated;
- (void)viewControllerDidRequestComposeEmail:(id)sender animated:(BOOL)animated;
@end

#endif
