//
//  MADTabBarController.h
//  MAD
//
//  Created by Michael Thomason on 10/26/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADTabBarController_h
#define Reports_MADTabBarController_h

#import <UIKit/UIKit.h>
#import "MADocumentProtocol.h"

extern const NSInteger MADIndexQuery;
extern const NSInteger MADIndexDesigner;
extern const NSInteger MADIndexViewer;

@class MADocument;

@interface MADTabBarController : UITabBarController
    <MADocumentProtocol>

@end

#endif
