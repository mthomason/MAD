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

@interface MTLicensingViewController : UITableViewController

@property (nonatomic, assign) IBOutlet id <MTViewControllerProtocol> delegate;

@end

#endif
