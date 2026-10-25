//
//  MADToolboxFormatViewController.h
//  Reports
//
//  Created by Michael Thomason on 3/16/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADToolboxFormatViewController_h
#define Reports_MADToolboxFormatViewController_h

#import <UIKit/UITableViewController.h>
#import "MADViewControllerDocumentProtocol.h"

@class MADocument;

@interface MADToolboxFormatViewController : UITableViewController <MADViewControllerDocumentProtocol>

@property (nonatomic, weak) MADocument *document;
@property (nonatomic, assign) BOOL clearsBackground;

@end

#endif
