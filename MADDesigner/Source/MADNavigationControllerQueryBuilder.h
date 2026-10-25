//
//  MADNavigationControllerQueryBuilder.h
//  MAD
//
//  Created by Michael Thomason on 10/18/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADNavigationControllerQueryBuilder_h
#define MAD_MADNavigationControllerQueryBuilder_h

#import "MADViewControllerDocumentProtocol.h"
#import "MADNavigationControllerIdentity.h"
#import <MADAPI/MADViewControllerStandardProtocol.h>
#import <UIKit/UINavigationController.h>

@interface MADNavigationControllerQueryBuilder : UINavigationController <MADNavigationControllerIdentify, MADViewControllerDocumentProtocol, MADViewControllerStandardProtocol>

@end

#endif
