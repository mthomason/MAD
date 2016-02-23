//
//  MADPageSlider.m
//  MAD Designer
//
//  Created by Michael Thomason on 2/21/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADPageSlider.h"
#import "MADSliderPageVertical.h"

@interface MADPageSlider ()

@property (nonatomic, weak) MADSliderPageVertical *slider;

@end

@implementation MADPageSlider

- (instancetype)init {
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
    if (self = [super initWithEffect:blurEffect]) {
        
        MADSliderPageVertical *vertSlider = [[MADSliderPageVertical alloc] init];
        [vertSlider addTarget:self action:@selector(handleSliderChangedPage:) forControlEvents:UIControlEventValueChanged];
        [vertSlider addTarget:self action:@selector(handleSliderDidFinishDrag:) forControlEvents:UIControlEventTouchUpInside];
        
        UITapGestureRecognizer *sliderTapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureTapSlider:)];
        [vertSlider addGestureRecognizer:sliderTapped];
        
        vertSlider.transform = CGAffineTransformRotate(vertSlider.transform, 1.0000f / 2.0000f * (CGFloat)M_PI);
        self.transform = CGAffineTransformRotate(vertSlider.transform, 3.0000f / 2.0000f * (CGFloat)M_PI);
        [self.contentView addSubview:vertSlider];
        
        self.slider = vertSlider;
        self.backgroundColor = [UIColor clearColor];
    
        
    }
    return self;
}

- (MADSliderPageVertical *)pageSlider { return self.slider; }

- (void)handleGestureTapSlider:(UIGestureRecognizer *)tap {
    UISlider *slider = (UISlider *)tap.view;
    if (slider.highlighted == NO) {
        CGPoint pt = [tap locationInView: slider];
        float percentage = (float)(pt.x / slider.bounds.size.width);
        float delta = percentage * (slider.maximumValue - slider.minimumValue);
        float value = slider.minimumValue + delta;
        [slider setValue:value animated:YES];
        [self handleSliderDidFinishDrag:slider];
        [self handleSliderChangedPage:slider];
    }
}

- (void)handleSliderChangedPage:(UISlider *)sender {
    [self.sliderDelegate sliderDidChangeToPage:lroundf(sender.value)];
}

- (void)handleSliderDidFinishDrag:(UISlider *)sender {
    sender.value = lroundf(sender.value);               // Sets your slider to this value
}

@end
