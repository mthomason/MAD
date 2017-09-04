//
//  MTLicensingViewController.h
//  Reports
//
//  Created by Michael Thomason on 6/26/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTLicensingViewController_h
#define Reports_MTLicensingViewController_h

#import <UIKit/UITableViewController.h>
#import <MADAPI/MADViewControllerStandardProtocol.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

@interface MTLicensingViewController : UITableViewController

    @property (nonatomic, weak) IBOutlet id <MADViewControllerStandardProtocol> delegate;

@end

#endif
