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

@end

@implementation MADOpenFileSectionHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {

        NSString *localizedTextCloud = NSLocalizedString(MADTextCloud, MADTextCloud);
        self.localizedTextCloud = localizedTextCloud;
        
        NSString *localizedTextLocal = NSLocalizedString(MADTextLocal, MADTextLocal);
        self.localizedTextLocal = localizedTextLocal;
        
        // Initalize the section type
        CGRect labelRect = CGRectMake(CGPointZero.x + 10.0000f, CGPointZero.y, frame.size.width - 10.0000f, frame.size.height);
        UILabel *label = [[UILabel alloc] initWithFrame:labelRect];
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        
        label.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        label.text = localizedTextLocal;
        self.sectionType = MACloudManagerSectionLocal;

        [self addSubview:label];
        self.backgroundColor = [UIColor lightGrayColor];
        
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        self.label = label;
    }
    return self;
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
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
