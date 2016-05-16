//
//  UISplitViewController+MADQuery.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/27/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_UINavigationController_MADQuery_h
#define MAD_Designer_UINavigationController_MADQuery_h

#import <UIKit/UINavigationController.h>
#import <MAD/MTQuery.h>

@interface UINavigationController (MADQuery)

    + (instancetype)QuerySplitViewController;
    + (instancetype)DesignerController;
    + (instancetype)ViewerController;

@end

#endif
