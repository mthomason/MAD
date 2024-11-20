//
//  MADNavigationControllerQueryBuilder.h
//  MAD
//
//  Created by Michael Thomason on 10/18/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADNavigationControllerQueryBuilder_h
#define MAD_MADNavigationControllerQueryBuilder_h

#import <UIKit/UINavigationController.h>
#import "MADViewControllerDocumentProtocol.h"
#import <MADAPI/MADViewControllerStandardProtocol.h>

@interface MADNavigationControllerQueryBuilder : UINavigationController
    <MADViewControllerDocumentProtocol, MADViewControllerStandardProtocol>

@end

#endif
