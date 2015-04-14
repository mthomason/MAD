//
//  MADToolboxViewController.h
//  MAD
//
//  Created by Michael Thomason on 10/28/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MADToolboxDisplayProtocol.h"

@class MADocument;

extern NSString * const MADToolbox;

@interface MADToolboxViewController : UIViewController
    <MADToolboxDisplayProtocol>

@property (nonatomic, strong) MADocument *document;
@property (nonatomic, copy) NSSet *selectedObjectIds;

@property (nonatomic, assign) BOOL clearsBackground;

@end
