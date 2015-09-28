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
#import <MAD/MADActivityProtocol.h>
#import "MADocumentProtocol.h"

@protocol MTViewControllerProtocol;

@interface MADViewerController : UIPageViewController
    <MADocumentProtocol,
        MADActivityProtocol,
        UIPageViewControllerDelegate,
        UIPageViewControllerDataSource,
        UIDocumentInteractionControllerDelegate>

@property (nonatomic, weak) id <MTViewControllerProtocol> viewControllerDelegate;

- (void)reload;

@end

#endif
