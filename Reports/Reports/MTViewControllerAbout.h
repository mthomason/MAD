//
//  MTViewControllerAbout.h
//  MAD
//
//  Created by Michael Thomason on 8/19/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTViewControllerAbout_h
#define Reports_MTViewControllerAbout_h

#import <Foundation/Foundation.h>
#import "MUIViewControllerDelegate.h"

@interface MTViewControllerAbout : UIViewController

@property (assign, nonatomic) IBOutlet id <MTViewControllerProtocol> delegate;

- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;
- (IBAction)composeEmail:(id)sender;

@end

#endif
