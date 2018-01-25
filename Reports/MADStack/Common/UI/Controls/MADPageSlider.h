//
//  MADPageSlider.h
//  MAD Designer
//
//  Created by Michael Thomason on 2/21/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADPageSlider_h
#define MAD_Designer_MADPageSlider_h

#import <UIKit/UIVisualEffectView.h>

@protocol MADPageSliderProtocol;

@class MADSliderPageVertical;

@interface MADPageSlider : UIVisualEffectView

    @property (nonatomic) NSUInteger numberOfPages;
    @property (nonatomic, getter=isEnabled) BOOL enabled;

    @property (nonatomic, weak) id <MADPageSliderProtocol> sliderDelegate;

    @property (readonly, weak, getter=pageSlider) MADSliderPageVertical *slider;

@end

#endif
