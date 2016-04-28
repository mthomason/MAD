//
//  UINavigationControllerModelControllers.h
//  Reports
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTNavigationController_h
#define Reports_MTNavigationController_h

#import <UIKit/UINavigationController.h>
#import <UIKit/UIViewControllerTransitioning.h>
#import "MADocumentProtocol.h"

@interface MADNavigationController : UINavigationController
    <MADViewControllerDocumentProtocol,
        UINavigationControllerDelegate,
        UIViewControllerTransitioningDelegate>

    - (IBAction)done:(id)sender;

@end

#endif
