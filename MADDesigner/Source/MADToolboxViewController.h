//
//  MADToolboxViewController.h
//  MAD
//
//  Created by Michael Thomason on 10/28/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADToolboxViewController_h
#define MAD_MADToolboxViewController_h

#import "MADToolboxDisplayProtocol.h"
#import "MADViewControllerDocumentProtocol.h"
#import <UIKit/UIViewController.h>

@class MADocument;

@interface MADToolboxViewController : UIViewController <MADToolboxDisplayProtocol, MADViewControllerDocumentProtocol>

@property (readwrite, nonatomic, weak) NSSet <NSNumber *> *selectedElementIDs;
@property (nonatomic, assign) BOOL clearsBackground;

+ (instancetype)newToolboxViewController;

@end

#endif
