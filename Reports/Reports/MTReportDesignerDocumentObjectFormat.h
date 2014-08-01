//
//  MTReportDesignerDocumentObjectFormat.h
//  Reports
//
//  Created by Michael Thomason on 3/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerDocumentObjectFormat_h
#define Reports_MTReportDesignerDocumentObjectFormat_h

#import <Foundation/Foundation.h>

@class MAReportDocument;

@interface MTReportDesignerDocumentObjectFormat : UITableViewController

@property (nonatomic, weak) MAReportDocument *document;

@end

#endif
