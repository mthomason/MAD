//
//  MUIViewControllerDelegate.h
//  Reports
//
//  Created by Michael Thomason on 11/1/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MUIViewControllerProtocol_h
#define Reports_MUIViewControllerProtocol_h

@protocol MTViewControllerProtocol
@optional
- (void)viewControllerDidFinish:(id)sender;
- (void)viewControllerDidCancel:(id)sender;
@end

#endif
