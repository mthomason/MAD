//
//  MTQueryBuilderContainerController.h
//  MTQueryBuilderContainerController
//
//  Created by Michael Thomason on 2/13/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryBuilderContainerController_h
#define Reports_MTQueryBuilderContainerController_h

#import <UIKit/UIKit.h>
#import "MTViewControllerAsyncProtocol.h"
#import "MUIViewControllerDelegate.h"

@class MTQueryBuilderViewController,
        MTQueryBuilderVisualizationViewController,
        MAReportDocument;

@interface MTQueryBuilderContainerController : UIViewController
    <MTViewControllerProtocol>

@property (nonatomic, weak) id <MTViewControllerProtocol> delegate;
@property (nonatomic, weak) id <MTViewControllerAsyncProtocol> delegateContentController;
@property (nonatomic, weak) MAReportDocument *document;

- (MTQueryBuilderViewController *)queryBuilderController;
- (MTQueryBuilderVisualizationViewController *)queryBuilderControllerAdvanced;

@end

#endif
