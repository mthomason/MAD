//
//  MADPageSlider.h
//  MAD Designer
//
//  Created by Michael Thomason on 2/21/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MADPageSliderProtocol <NSObject>

- (void)sliderDidChangeToPage:(NSInteger)page;

@end

@class MADSliderPageVertical;

@interface MADPageSlider : UIVisualEffectView

@property (nonatomic, weak) id <MADPageSliderProtocol> sliderDelegate;
@property (readonly) MADSliderPageVertical *pageSlider;

@property(nonatomic,getter=isEnabled) BOOL enabled;

@property(nonatomic) float value;
@property(nonatomic) float minimumValue;
@property(nonatomic) float maximumValue;

@end
