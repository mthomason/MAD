//
//  MADOpenFileSectionHeaderView.m
//  MAD
//
//  Created by Michael Thomason on 10/8/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADOpenFileSectionHeaderView.h"
#import "UIColor+EverydayApps.h"

NSString * const MADTextCloud = @"Cloud";
NSString * const MADTextLocal = @"Local";

@interface MADOpenFileSectionHeaderView ()

@property (nonatomic, strong) UILabel *label;

@property (nonatomic, strong) NSString *localizedTextCloud;
@property (nonatomic, strong) NSString *localizedTextLocal;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@end

@implementation MADOpenFileSectionHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {

        [[UIActivityIndicatorView appearanceWhenContainedIn:[MADOpenFileSectionHeaderView class], nil] setTintColor:[UIColor whiteColor]];
        [[UIActivityIndicatorView appearanceWhenContainedIn:[MADOpenFileSectionHeaderView class], nil] setColor:[UIColor whiteColor]];
        
        NSString *localizedTextCloud = NSLocalizedString(MADTextCloud, MADTextCloud);
        self.localizedTextCloud = localizedTextCloud;
        
        NSString *localizedTextLocal = NSLocalizedString(MADTextLocal, MADTextLocal);
        self.localizedTextLocal = localizedTextLocal;
        
        // Initalize the section type
        CGRect labelRect = CGRectMake(CGPointZero.x + 10.0000f, CGPointZero.y, frame.size.width - 10.0000f, frame.size.height);
        UILabel *label = [[UILabel alloc] initWithFrame:labelRect];
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        label.textAlignment = NSTextAlignmentLeft;
        label.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        label.text = localizedTextLocal;
        self.sectionType = MACloudManagerSectionLocal;

        [self addSubview: label];

        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        activityView.hidesWhenStopped = YES;
        activityView.frame = CGRectMake(self.frame.size.width - activityView.frame.size.width - 10.0000f,
                                        ((self.frame.size.height - activityView.frame.size.height) / 2.0000f),
                                        activityView.frame.size.width,
                                        activityView.frame.size.height);
        [activityView stopAnimating];
        activityView.tintColor = [UIColor whiteColor];
        activityView.color = [UIColor whiteColor];
        [self addSubview: activityView];

        self.activityIndicatorView = activityView;

        self.backgroundColor = [UIColor edaBlackFiftyPercent];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        
        self.label = label;
        
    }
    return self;
}

- (void)startAnimating {
    [self.activityIndicatorView startAnimating];
}

- (void)stopAnimating {
    [self.activityIndicatorView stopAnimating];
}

- (void)setSectionType:(MACloudManagerSection)sectionType {
    if (_sectionType != sectionType) {
        _sectionType = sectionType;
        [self setNeedsDisplay];
    }
}

- (void)setNeedsDisplay {
    [super setNeedsDisplay];
    if (self.label != nil) {
        switch (self.sectionType) {
                
            case MACloudManagerSectionCloud:
                self.label.text = self.localizedTextCloud;
                break;
                
            case MACloudManagerSectionLocal:
                self.label.text = self.localizedTextLocal;
                break;
                
            case MACloudManagerSectionCombined:
                self.label.text = @"";
                break;
                
            default:
                self.label.text = @"";
                break;
        }
    }
    [self.label sizeToFit];
    //self.label.center = CGPointMake(self.label.center.x, self.center.y);
    self.label.frame = CGRectMake(CGPointZero.x + 10.0000f, CGPointZero.y, self.label.frame.size.width + 5.0000f, self.frame.size.height);
    self.activityIndicatorView.frame = CGRectMake(self.label.frame.origin.x + self.label.frame.size.width + 5.0000f,
                                                  self.activityIndicatorView.frame.origin.y,
                                                  self.activityIndicatorView.frame.size.width,
                                                  self.activityIndicatorView.frame.size.height);
}
- (void)layoutSubviews {
 /*   self.activityIndicatorView.frame = CGRectMake(self.label.frame.origin.x + self.label.frame.size.width + 5.0000f,
                                                  self.activityIndicatorView.frame.origin.y,
                                                  self.activityIndicatorView.frame.size.width,
                                                  self.activityIndicatorView.frame.size.height);*/
    [super layoutSubviews];
}

@end
