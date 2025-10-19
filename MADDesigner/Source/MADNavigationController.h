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

@interface MADNavigationController : UINavigationController <UINavigationControllerDelegate, UIViewControllerTransitioningDelegate, MADNavigationProtocol, MADViewControllerDocumentProtocol, MADNavigationControllerIdentify>

@property (readonly, nonatomic, assign) MADNavigationControllerType controllerType;
@property (nonatomic, weak) id <MADViewControllerStandardProtocol> viewControllerDelegate;

- (IBAction)done:(id)sender;
- (void)done:(id)sender completion:(void (^)(void))completion;

@end

@interface UINavigationController (Constructors)

+ (UINavigationController <MADViewControllerDocumentProtocol, MADNavigationProtocol> *)documentNavigationControllerWithType:(MADNavigationControllerType)type
																												   document:(MADocument *)document;
+ (UINavigationController *)navigationControllerWithType:(MADNavigationControllerType)type;

@end

#endif
