//
//  MADQueryVisualizationSchemaAnimatedTransitioning.h
//  MAD Designer
//
//  Created by Michael Thomason on 10/10/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADQueryVisualizationSchemaAnimatedTransitioning_h
#define MAD_Designer_MADQueryVisualizationSchemaAnimatedTransitioning_h

#import <Foundation/NSObject.h>
#import <UIKit/UIViewControllerTransitioning.h>

@interface MADQueryVisualizationSchemaAnimatedTransitioning : NSObject
    <UIViewControllerAnimatedTransitioning>

@end

@interface MADQueryVisualizationSchemaAnimatedTransitioningDelegate : NSObject
    <UIViewControllerTransitioningDelegate>

@end


#endif
