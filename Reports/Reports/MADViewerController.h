//
//  MTReportViewerController2.h
//  Reports
//
//  Created by Michael Thomason on 7/20/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportViewerController_h
#define Reports_MTReportViewerController_h

#import <UIKit/UIKit.h>
#import "MADocumentProtocol.h"
#import "MUIViewControllerDelegate.h"
#import "MADActivityProtocol.h"

@interface MADViewerController : UIPageViewController
    <MADocumentProtocol, UIPageViewControllerDelegate, UIPageViewControllerDataSource,
        UIDocumentInteractionControllerDelegate, MADActivityProtocol>

@property (nonatomic, weak) id <MTViewControllerProtocol> viewControllerDelegate;

- (void)reload;

@end

#endif
