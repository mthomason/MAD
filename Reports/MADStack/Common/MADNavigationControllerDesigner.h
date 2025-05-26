//
//  MADNavigationControllerDesigner.h
//  MAD Designer
//
//  Created by Michael on 2/18/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADNavigationControllerDesigner_h
#define Reports_MADNavigationControllerDesigner_h

#import "MADTabBarItemProtocol.h"
#import "MADNavigationControllerIdentity.h"
#import "MADViewControllerDocumentProtocol.h"
#import <MADAPI/MADViewControllerStandardProtocol.h>

#import <UIKit/UINavigationController.h>

@protocol MADViewControllerStandardProtocol;

@interface MADNavigationControllerDesigner : UINavigationController <MADNavigationControllerIdentify, MADTabBarImageProtocol, MADViewControllerDocumentProtocol>

@property (nonatomic, weak) id <MADViewControllerStandardProtocol> viewControllerDelegate;

@end

#endif
