//
//  MADDocumentInformationTableViewController.h
//  MAD
//
//  Created by Michael Thomason on 3/15/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDocumentInformationTableViewController_h
#define Reports_MADDocumentInformationTableViewController_h

#import <UIKit/UITableViewController.h>

@class MADMetaData;

@interface MADDocumentInformationTableViewController : UITableViewController

    @property (nonatomic, strong) NSArray <__kindof MADMetaData *> *metadataItems;

@end

#endif
