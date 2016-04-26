//
//  MADDesignerStoryboard.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/5/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADStoryboard_h
#define MAD_Designer_MADStoryboard_h

#import <UIKit/UIStoryboard.h>

@interface MADStoryboard : UIStoryboard

    + (instancetype)newStoryboardDesigner;
    + (instancetype)newStoryboardQuery;
    + (instancetype)newToolbox;
    + (instancetype)newLicensing;

@end

#endif
