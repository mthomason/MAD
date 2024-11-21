//
//  UINavigationControllerModelControllers.h
//  Reports
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTNavigationController_h
#define Reports_MTNavigationController_h

#import <UIKit/UINavigationController.h>
#import <UIKit/UIViewControllerTransitioning.h>
#import "MADViewControllerDocumentProtocol.h"
#import "MADNavigationControllerIdentity.h"

@protocol MADViewControllerStandardProtocol;

@interface MADNavigationController : UINavigationController
	<UINavigationControllerDelegate,
		UIViewControllerTransitioningDelegate,
		MADViewControllerDocumentProtocol,
		MADNavigationControllerIdentify>

	+ (instancetype)newNavigationController:(MADNavigationControllerType)type;

	@property (readonly, nonatomic, assign) MADNavigationControllerType controllerType;
	@property (nonatomic, weak) id <MADViewControllerStandardProtocol> viewControllerDelegate;

	- (IBAction)done:(id)sender;

@end

#endif
