//
//  MADToolboxViewController.h
//  MAD
//
//  Created by Michael Thomason on 10/28/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADToolboxViewController_h
#define MAD_MADToolboxViewController_h

#import <UIKit/UIViewController.h>
#import "MADToolboxDisplayProtocol.h"
#import "MADViewControllerDocumentProtocol.h"

@class MADocument;

@interface MADToolboxViewController : UIViewController
    <MADToolboxDisplayProtocol, MADViewControllerDocumentProtocol>

    + (instancetype)newToolboxViewController;

    @property (readwrite, nonatomic, weak) NSSet <NSNumber *> *selectedElementIDs;

    @property (nonatomic, assign) BOOL clearsBackground;

@end

#endif
