//
//  MADSearchBar.m
//  MAD
//
//  Created by Michael Thomason on 10/16/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADSearchBar.h"
#import "objcmad.h"

@interface MADSearchBar ()

@property (nonatomic, assign, getter=isIconColorUpdated) BOOL updatedIconColor;
@property (nonatomic, assign, getter=isClearButtonUpdated) BOOL updatedClearButtonColor;

@end

@implementation MADSearchBar

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[UIButton appearanceWhenContainedIn: [UISearchBar class], nil] setTintColor:[UIColor whiteColor]];
    });
}

- (instancetype)initWithFrame:(CGRect)frame {

    if (self = [super initWithFrame:frame]) {
        self.updatedIconColor = NO;
        self.updatedClearButtonColor = NO;
        UIImage *closeImage = [UIImage imageNamed:@"MADImageClear"];
        UIImage *newImageTemplate = [closeImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self setImage:newImageTemplate forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];
        
    }
    return self;
}


- (void)setNeedsDisplay {
    [super setNeedsDisplay];
}

- (void)setNeedsLayout {
    [super setNeedsLayout];
    [self setupIfNeeded];
}

- (void)setupIfNeeded {
    if (self.isIconColorUpdated == NO || self.isClearButtonUpdated == NO) {
        for (UIView *subview in self.subviews) {
            for (id subview2 in subview.subviews) {
                if ([subview2 isKindOfClass:[UITextField class]]) {
                    ((UITextField *)subview2).textColor = [UIColor whiteColor];
                    ((UITextField *)subview2).tintColor = [UIColor whiteColor];
                    
                    ((UIImageView *)((UITextField *)subview2).leftView).image = [((UIImageView *)((UITextField *)subview2).leftView).image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                    ((UIImageView *)((UITextField *)subview2).leftView).tintColor = [UIColor whiteColor];
                    
                }
            }
            if (self.isIconColorUpdated && self.isClearButtonUpdated) {
                break;
            }
        }
    }
}

- (void)layoutIfNeeded {
    [super layoutIfNeeded];
    [self setupIfNeeded];
}

@end
