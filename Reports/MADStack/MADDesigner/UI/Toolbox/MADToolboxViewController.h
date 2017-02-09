//
//  MADToolboxViewController.h
//  MAD
//
//  Created by Michael Thomason on 10/28/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADToolboxViewController_h
#define MAD_MADToolboxViewController_h

#import "MADViewController.h"
#import "MADToolboxDisplayProtocol.h"
#import "MADViewControllerDocumentProtocol.h"

@class MADocument;

@interface MADToolboxViewController : MADViewController
    <MADToolboxDisplayProtocol, MADViewControllerDocumentProtocol>

    + (instancetype)newToolboxViewController;

    @property (nonatomic, strong) NSSet <NSNumber *> *selectedObjectIds;

    @property (nonatomic, assign) BOOL clearsBackground;

@end

#endif
