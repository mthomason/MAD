//
//  MADViewerController.h
//  Reports
//
//  Created by Michael Thomason on 7/20/13.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportViewerController_h
#define Reports_MTReportViewerController_h

#import <UIKit/UIKit.h>
#import <MAD/MADConstants.h>
#import <MAD/MAD.h>
#import <MAD/MADActivityProtocol.h>
#import <MAD/MTQuery.h>
#import <MAD/MTActivityItemProviderPdf.h>
#import <MAD/MTNotificationDidFormatPage.h>
#import <MAD/MTNotificationDidReadRows.h>
#import <MAD/MTKeyChain.h>

#import <MADDataStructures/MADDataStructures.h>
#import <MADFoundation/MTDataTable.h>
#import "MADocumentProtocol.h"
#import "MUIViewControllerDelegate.h"

@interface MADViewerController : UIPageViewController
    <MADocumentProtocol, UIPageViewControllerDelegate, UIPageViewControllerDataSource,
        UIDocumentInteractionControllerDelegate, MADActivityProtocol>

@property (nonatomic, weak) id <MTViewControllerProtocol> viewControllerDelegate;

- (void)reload;

@end

#endif
