//
//  MADDocumentInformationTableViewController.h
//  MAD
//
//  Created by Michael Thomason on 3/15/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADDocumentInformationTableViewController_h
#define MAD_Designer_MADDocumentInformationTableViewController_h

#import <UIKit/UITableViewController.h>

@interface MADDocumentInformationTableViewController : UITableViewController

	+ (instancetype)newDocumentInformationTableViewController;

	@property (nonatomic, strong) NSArray *metadataItems;

@end

#endif
