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
#import "MADViewControllerDocumentProtocol.h"
#import "MADNavigationControllerIdentity.h"

@interface MADNavigationController : UINavigationController
    <UINavigationControllerDelegate,
        UIViewControllerTransitioningDelegate,
        MADViewControllerDocumentProtocol, MADNavigationControllerIdentify>

    + (instancetype)newNavigationController:(MADNavigationControllerType)type;

    @property (readonly, nonatomic, assign) MADNavigationControllerType controllerType;

    - (IBAction)done:(id)sender;

@end

#endif
