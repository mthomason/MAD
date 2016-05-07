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

+ (void)initialize {
    if (self == [MADSearchBar self]) {
        Class searchBar = [UISearchBar class];
        UIButton *button = [UIButton appearanceWhenContainedIn: searchBar, nil];
        UIColor *white = [UIColor whiteColor];
        button.tintColor = white;
    }
}

- (instancetype)initWithFrame:(CGRect)frame {

    if (self = [super initWithFrame:frame]) {
        self.updatedIconColor = NO;
        self.updatedClearButtonColor = NO;
        UIImage *closeImage = [UIImage imageNamed:@"MADImageClear"];
        UIImage *newImageTemplate = [closeImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self setImage:newImageTemplate forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];
        self.showsBookmarkButton = NO;
        self.showsCancelButton = YES;
        self.showsScopeBar = NO;
        self.showsSearchResultsButton = NO;
        self.hidden = YES;
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
        UIImage * __unsafe_unretained image;
        UIColor *whiteColor =  [UIColor whiteColor];
        for (UIView *subview in self.subviews) {
            for (id subview2 in subview.subviews) {
                if ([subview2 isKindOfClass:[UITextField class]]) {
                    ((UITextField *)subview2).textColor = whiteColor;
                    ((UITextField *)subview2).tintColor = whiteColor;
                    
                    image = ((UIImageView *)((UITextField *)subview2).leftView).image;
                    UIImage *imageRenderingTemplate = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                    ((UIImageView *)((UITextField *)subview2).leftView).image = imageRenderingTemplate;
                    ((UIImageView *)((UITextField *)subview2).leftView).tintColor = whiteColor;
                    
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
