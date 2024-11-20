//
//  MADQueryVisualizationScrollView.h
//  MAD Designer
//
//  Created by Michael Thomason on 10/10/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADQueryVisualizationScrollView_h
#define MAD_Designer_MADQueryVisualizationScrollView_h

#import <UIKit/UIScrollView.h>

@class MADQueryVisualizationContentView;

@interface MADQueryVisualizationScrollView : UIScrollView

    @property (nonatomic, strong, readonly) MADQueryVisualizationContentView *contentView;

@end

#endif
