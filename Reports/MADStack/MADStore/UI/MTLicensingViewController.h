//
//  MTLicensingViewController.h
//  Reports
//
//  Created by Michael Thomason on 6/26/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTLicensingViewController_h
#define Reports_MTLicensingViewController_h

#import "MUIViewControllerDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import <MADCocoaExtensions/MADColor.h>
#import <MADCocoaExtensions/MADDevice.h>

@interface MTLicensingViewController : UITableViewController

@property (nonatomic, weak) IBOutlet id <MTViewControllerProtocol> delegate;

@end

#endif
