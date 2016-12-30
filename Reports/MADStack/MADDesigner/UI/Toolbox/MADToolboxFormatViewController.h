//
//  MTReportDesignerDocumentObjectFormat.h
//  Reports
//
//  Created by Michael Thomason on 3/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerDocumentObjectFormat_h
#define Reports_MTReportDesignerDocumentObjectFormat_h

#import <UIKit/UITableViewController.h>
#import "MADViewControllerDocumentProtocol.h"

@class MADocument;

@interface MADToolboxFormatViewController : UITableViewController
    <MADViewControllerDocumentProtocol>

    @property (nonatomic, weak) MADocument *document;
    @property (nonatomic, assign) BOOL clearsBackground;

@end

#endif
