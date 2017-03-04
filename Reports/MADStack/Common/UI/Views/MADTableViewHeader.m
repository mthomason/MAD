//
//  MADViewTableHeader.m
//  Reports
//
//  Created by Michael Thomason on 1/27/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADTableViewHeader.h"
#import <UIKit/UILabel.h>
#import <UIKit/UIButton.h>
#import <UIKit/UINibLoading.h>
#import <Foundation/NSBundle.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

@interface MADTableViewHeader ()

    @property (nonatomic, weak) UIView *nibView;

@end

@implementation MADTableViewHeader

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        NSArray *nibContents =  [[NSBundle mainBundle] loadNibNamed: @"MADTableViewHeader"
                                                              owner: self options: nil];
        
        UIView *view = nibContents.firstObject;
        view.frame = self.frame;
        
        self.labelTitle.textColor = [MADColorEverydayApps newColorRed];
        self.buttonAdd.tintColor = [MADColorEverydayApps newColorBlue];

        [self addSubview:view];
        self.nibView = view;
        
        self.labelTitle.numberOfLines = 0;
        self.labelTitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        self.backgroundColor = [MADColorEverydayApps newColorHeaderColor];
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.labelTitle sizeToFit];
}

@end
