//
//  MADQueryVisualizationScrollView.h
//  MAD Designer
//
//  Created by Michael Thomason on 10/10/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MADQueryVisualizationContentView;

@interface MADQueryVisualizationScrollView : UIScrollView

@property (nonatomic, strong, readonly) MADQueryVisualizationContentView *contentView;

@end
