//
//  MADOpenFileSectionHeaderView.m
//  MAD
//
//  Created by Michael Thomason on 10/8/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADOpenFileSectionHeaderView.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/UIView+Animations.h>

#import <UIKit/UIActivityIndicatorView.h>
#import <UIKit/UINibLoading.h>
#import <UIKit/UILabel.h>
#import <UIKit/NSAttributedString.h>

NSString * const MADTextCloud = @"Cloud";
NSString * const MADTextLocal = @"Local";

@interface MADOpenFileSectionHeaderView ()

@property (nonatomic, strong) UILabel *label;

@property (nonatomic, strong) NSString *localizedTextCloud;
@property (nonatomic, strong) NSString *localizedTextLocal;
@property (nonatomic, strong) NSAttributedString *localizedAttrbiutedTextCloud;
@property (nonatomic, strong) NSAttributedString *localizedAttrbiutedTextLocal;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic, strong) NSString *fontType;

@end

@implementation MADOpenFileSectionHeaderView

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    return [super preferredLayoutAttributesFittingAttributes:layoutAttributes];
}

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
        label.textAlignment = NSTextAlignmentLeft;
        self.fontType = UIFontTextStyleHeadline;
        label.font = [UIFont preferredFontForTextStyle:self.fontType];
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
        
        UIColor *foregroundColor = [MADColorEverydayApps newColorRed];
        NSDictionary *attributesLocal = @{NSForegroundColorAttributeName : foregroundColor};
        
        NSAttributedString *attributedStringLocal = [[NSAttributedString alloc] initWithString: localizedTextLocal
                                                                                    attributes: attributesLocal];
        self.localizedAttrbiutedTextLocal = attributedStringLocal;
        
        NSAttributedString *attributedStringCloud = [[NSAttributedString alloc] initWithString: localizedTextCloud
                                                                                    attributes: attributesLocal];
        self.localizedAttrbiutedTextCloud = attributedStringCloud;
        
        UIColor *blueColor = [MADColorEverydayApps newColorHeaderColor];
        self.backgroundColor = blueColor;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = foregroundColor;
        
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
        self.label.font = [UIFont preferredFontForTextStyle:self.fontType];
        switch (self.sectionType) {
                
            case MACloudManagerSectionCloud:
                self.label.attributedText = self.localizedAttrbiutedTextCloud;
                break;
                
            case MACloudManagerSectionLocal:
                self.label.attributedText = self.localizedAttrbiutedTextLocal;
                break;
                                
            default:
                self.label.attributedText = nil;
                self.label.text = @"";
                break;
        }
    }
    [self.label sizeToFit];
    self.label.frame = CGRectMake(CGPointZero.x + 10.0000f, CGPointZero.y, self.label.frame.size.width + 5.0000f, self.frame.size.height);
    self.activityIndicatorView.frame = CGRectMake(self.label.frame.origin.x + self.label.frame.size.width + 5.0000f,
                                                  self.activityIndicatorView.frame.origin.y,
                                                  self.activityIndicatorView.frame.size.width,
                                                  self.activityIndicatorView.frame.size.height);
}

@end
