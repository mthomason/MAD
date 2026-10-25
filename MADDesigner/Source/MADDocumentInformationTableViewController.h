//
//  MADDocumentInformationTableViewController.h
//  MAD
//
//  Created by Michael Thomason on 3/15/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADDocumentInformationTableViewController_h
#define MAD_Designer_MADDocumentInformationTableViewController_h

#import <UIKit/UITableViewController.h>

@interface MADDocumentInformationTableViewController : UITableViewController

	+ (instancetype)newDocumentInformationTableViewController;

	@property (nonatomic, strong) NSArray *metadataItems;

@end

#endif
