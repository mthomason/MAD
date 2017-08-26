//
//  MADDatabaseTableSectionHeaderView.m
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDatabaseTableSectionHeaderView.h"

#import <UIKit/UIFont.h>
#import <UIKit/UIButton.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIAccessibility.h>
#import <UIKit/UITapGestureRecognizer.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import "MADSectionHeaderViewDelegate.h"

static NSString * const TextAccessibilityHint = @"Toggles database field visibility.";
static const CGFloat ButtonSize = 35.00000f;
static const CGFloat PaddingSize = 5.00000f;

@interface MADDatabaseTableSectionHeaderView ()

    @property (readwrite, nonatomic, weak) UILabel *titleLabel;
    @property (readwrite, nonatomic, weak) UIButton *disclosureButton;

@end

@implementation MADDatabaseTableSectionHeaderView

- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title.copy;
}

- (instancetype)initWithReuseIdentifier:(nullable NSString *)reuseIdentifier {
    if (self = [super initWithReuseIdentifier:reuseIdentifier]) {
        [self initalize];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initalize];
    }
    return self;
}

- (void)initalize {
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.isAccessibilityElement = NO;
    label.text = @"";
    
    UIFont *font = [UIFont boldSystemFontOfSize:17.0000f];
    label.font = font;
    
    UIColor *blueColor = [MADColorEverydayApps newColorBlue];
    label.textColor = blueColor;
    label.backgroundColor =  [UIColor clearColor];
    
    [self.contentView addSubview:label];
    self.titleLabel = label;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.isAccessibilityElement = NO;
    
    UIImage *caratOpen = [UIImage imageNamed:@"MADImageCaratOpen"];
    UIImage *caratClosed = [UIImage imageNamed:@"MADImageCarat"];
    
    [button setImage: caratClosed   forState: UIControlStateNormal];
    [button setImage: caratOpen     forState: UIControlStateSelected];
    [button addTarget: self
               action: @selector(toggleOpen:)
     forControlEvents: UIControlEventTouchUpInside];
    [self.contentView addSubview:button];
    
    // Set up the tap gesture recognizer.
    UITapGestureRecognizer *tapGesture;
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                         action: @selector(toggleOpen:)];
    [self addGestureRecognizer:tapGesture];
    tapGesture = nil;
    
    self.disclosureButton = button;
    
    self.contentView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.userInteractionEnabled = YES;
}

- (IBAction)toggleOpen:(id)sender {
    [self toggleOpenWithUserAction:YES];
}

- (void)toggleOpenWithUserAction:(BOOL)userAction {
    UIButton *disclosureButton = self.disclosureButton;
    (disclosureButton).selected = !disclosureButton.isSelected;
    
    if (userAction) {
        id <MADSectionHeaderViewDelegate> superDelegate = self.delegate;
        if ((disclosureButton).selected) {
            if ([superDelegate respondsToSelector:@selector(sectionHeaderView:sectionOpened:)]) {
                [superDelegate sectionHeaderView:self sectionOpened:self.section];
            }
        } else {
            if ([superDelegate respondsToSelector:@selector(sectionHeaderView:sectionClosed:)]) {
                [superDelegate sectionHeaderView:self sectionClosed:self.section];
            }
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect titleLabelFrame = self.bounds;
    titleLabelFrame.origin.x += ButtonSize;
    titleLabelFrame.size.width -= ButtonSize;
    CGRectInset(titleLabelFrame, 0.0000f, PaddingSize);
    self.titleLabel.frame = titleLabelFrame;
    self.disclosureButton.frame = CGRectMake(self.bounds.origin.x, PaddingSize, ButtonSize, ButtonSize);

}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    UIColor *color = [UIColor whiteColor];
    self.titleLabel.textColor = color;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    UIColor *color = [MADColorEverydayApps newColorBlue];
    self.titleLabel.textColor = color;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    UIColor *color = [MADColorEverydayApps newColorBlue];
    self.titleLabel.textColor = color;
}

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement {
    return YES;
}

- (NSString *)accessibilityLabel {
    return self.titleLabel.text;
}

- (NSString *)accessibilityHint {
    return NSLocalizedString(TextAccessibilityHint, TextAccessibilityHint);
}

@end
