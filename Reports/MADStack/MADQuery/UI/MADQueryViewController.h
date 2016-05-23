//
//  MADQueryViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADQueryViewController_h
#define Reports_MADQueryViewController_h

#import "MADTableViewController.h"
#import <MAD/MTQueryTest.h>
#import <MAD/NSManagedObject+Extras.h>
#import "MADocumentProtocol.h"
#import "MUIViewControllerDelegate.h"

extern NSString * const MADImageBarButtonItemDatabase;
extern NSString * const MADImageBarButtonItemDatabase8;
extern NSString * const MADSegueShowSql;

@class MADocument;

@interface MADQueryViewController : MADTableViewController
    <MADViewControllerDocumentProtocol>

    @property (nonatomic, weak) IBOutlet id <MTViewControllerProtocol> delegate;

    + (void)deleteCoreDataCache;
    - (void)reloadMainDocumentAnimated:(BOOL)animated;
    - (IBAction)edit:(id)sender;

@end

#endif
