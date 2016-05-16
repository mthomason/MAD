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

@class MADocument;

@interface MADToolboxViewController : MADViewController
    <MADToolboxDisplayProtocol>

    @property (nonatomic, weak) MADocument *document;
    @property (nonatomic, copy) NSSet *selectedObjectIds;

    @property (nonatomic, assign) BOOL clearsBackground;

@end

#endif
