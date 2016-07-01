//
//  UINavigationController+Designer.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_UINavigationController_Extras_h
#define MAD_Designer_UINavigationController_Extras_h

#import <UIKit/UINavigationController.h>

@interface UINavigationController (Designer)

    + (instancetype)newNavigationControllerAppInformation;
    + (instancetype)newNavigationControllerLicensing;
    + (instancetype)newNavigationControllerNewDocument;
    + (instancetype)newNavigationControllerToolbox;
    + (instancetype)newNavigationControllerFontPicker;
    + (instancetype)newNavigationControllerAggregateAdd;
    + (instancetype)newNavigationControllerElementPicker;

@end

#endif
