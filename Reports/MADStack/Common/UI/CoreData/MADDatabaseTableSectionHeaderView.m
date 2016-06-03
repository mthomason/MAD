//
//  MADDatabaseTableSectionHeaderView.m
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2016 Everyday Apps LLC. All rights reserved.
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

    @property (nonatomic, strong) UILabel *titleLabel;
    @property (nonatomic, strong) UIButton *disclosureButton;
    @property (nonatomic, assign) NSInteger section;
    @property (nonatomic, weak) id <MADSectionHeaderViewDelegate> delegate;

@end

@implementation MADDatabaseTableSectionHeaderView


- (instancetype)initWithFrame:(CGRect)frame title:(NSString*)title section:(NSInteger)sectionNumber delegate:(id <MADSectionHeaderViewDelegate>)delegate {
    
    if (self = [self initWithFrame:frame]) {
        
        _delegate =  delegate;
        _section = sectionNumber;
        CGRect titleLabelFrame = self.bounds;
        titleLabelFrame.origin.x += ButtonSize;
        titleLabelFrame.size.width -= ButtonSize;
        CGRectInset(titleLabelFrame, 0.0000f, PaddingSize);

        UILabel *label = [[UILabel alloc] initWithFrame:titleLabelFrame];
        label.isAccessibilityElement = NO;
        label.text = title;
        
        UIFont *font = [UIFont boldSystemFontOfSize:17.0000f];
        label.font = font;
        
        UIColor *blueColor = [MADColorEverydayApps newColorBlue];
        label.textColor = blueColor;
        label.backgroundColor =  [UIColor clearColor];
        
        [self addSubview:label];
        self.titleLabel = label;
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.isAccessibilityElement = NO;
        button.frame = CGRectMake(0.0000f, PaddingSize, ButtonSize, ButtonSize);
        
        UIImage *caratOpen = [UIImage imageNamed:@"MADImageCaratOpen"];
        UIImage *caratClosed = [UIImage imageNamed:@"MADImageCarat"];
        
        [button setImage: caratClosed   forState:UIControlStateNormal];
        [button setImage: caratOpen     forState:UIControlStateSelected];
        [button addTarget:self action:@selector(toggleOpen:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];

        // Set up the tap gesture recognizer.
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleOpen:)];
        [self addGestureRecognizer:tapGesture];
        
        self.disclosureButton = button;
        
        self.backgroundColor = [UIColor groupTableViewBackgroundColor];
        self.userInteractionEnabled = YES;
    }
    
    return self;
}

- (IBAction)toggleOpen:(id)sender {
    [self toggleOpenWithUserAction:true];
}


- (void)toggleOpenWithUserAction:(bool)userAction {
    
    (self.disclosureButton).selected = !self.disclosureButton.isSelected;
    
    if (userAction) {
        id <MADSectionHeaderViewDelegate> superDelegate = self.delegate;
        if ((self.disclosureButton).selected) {
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
