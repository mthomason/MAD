//
//  MADNavigationControllerViewer.h
//  MAD Designer
//
//  Created by Michael on 1/4/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADNavigationControllerViewer_h
#define Reports_MADNavigationControllerViewer_h

#import "MADTabBarItemProtocol.h"
#import "MADNavigationControllerIdentity.h"
#import "MADViewControllerDocumentProtocol.h"
#import <MADAPI/MADViewControllerStandardProtocol.h>
#import <UIKit/UINavigationController.h>

@protocol MADViewControllerStandardProtocol;

@interface MADNavigationControllerViewer : UINavigationController <MADNavigationControllerIdentify, MADTabBarImageProtocol, MADViewControllerDocumentProtocol>

	@property (nonatomic, weak) id <MADViewControllerStandardProtocol> viewControllerDelegate;

@end

#endif
