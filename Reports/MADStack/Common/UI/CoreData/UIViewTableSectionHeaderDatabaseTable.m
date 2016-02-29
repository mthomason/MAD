//
//  CoreDataTableViewController.m
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "UIViewTableSectionHeaderDatabaseTable.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

@interface UIViewTableSectionHeaderDatabaseTable ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *disclosureButton;
@property (nonatomic, assign) NSInteger section;
@property (nonatomic, weak) id <MADSectionHeaderViewDelegate> delegate;

@end

@implementation UIViewTableSectionHeaderDatabaseTable


- (instancetype)initWithFrame:(CGRect)frame title:(NSString*)title section:(NSInteger)sectionNumber delegate:(id <MADSectionHeaderViewDelegate>)delegate {
    
    if (self = [self initWithFrame:frame]) {
        
        // Set up the tap gesture recognizer.
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleOpen:)];
        [self addGestureRecognizer:tapGesture];
        
        self.delegate =  delegate;
        [self setUserInteractionEnabled: YES];
        
        [self setSection: sectionNumber];
        CGRect titleLabelFrame = self.bounds;
        titleLabelFrame.origin.x += 35.00000f;
        titleLabelFrame.size.width -= 35.0000f;
        CGRectInset(titleLabelFrame, 0.0000f, 5.0000f);

        UILabel *label = [[UILabel alloc] initWithFrame:titleLabelFrame];
        label.isAccessibilityElement = NO;
        label.text = title;
        UIFont *font = [UIFont boldSystemFontOfSize:17.0000f];
        label.font = font;
        UIColor *blueColor = [UIColor tintColorBlue];
        label.textColor = blueColor;
        label.backgroundColor =  [UIColor clearColor];
        [self addSubview:label];
        self.titleLabel = label;
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.isAccessibilityElement = NO;
        button.frame = CGRectMake(0.0000f, 5.0000f, 35.0000f, 35.0000f);
        
        UIImage *caratOpen = [UIImage imageNamed:@"MADImageCaratOpen"];
        UIImage *caratClosed = [UIImage imageNamed:@"MADImageCarat"];
        [button setImage:caratClosed forState:UIControlStateNormal];
        [button setImage:caratOpen forState:UIControlStateSelected];
        [button addTarget:self action:@selector(toggleOpen:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        
        self.disclosureButton = button;
        
        self.backgroundColor = [UIColor groupTableViewBackgroundColor];
    }
    
    return self;
}

- (IBAction)toggleOpen:(id)sender {
    [self toggleOpenWithUserAction:YES];
}


- (void)toggleOpenWithUserAction:(BOOL)userAction {
    
    [self.disclosureButton setSelected: ![self.disclosureButton isSelected]];
    
    if (userAction) {
        if ([self.disclosureButton isSelected]) {
            if ([self.delegate respondsToSelector:@selector(sectionHeaderView:sectionOpened:)]) {
                [self.delegate sectionHeaderView:self sectionOpened:[self section]];
            }
        }
        else {
            if ([self.delegate respondsToSelector:@selector(sectionHeaderView:sectionClosed:)]) {
                [self.delegate sectionHeaderView:self sectionClosed:[self section]];
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
    UIColor *color = [UIColor tintColorBlue];
    self.titleLabel.textColor = color;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    UIColor *color = [UIColor tintColorBlue];
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
    return NSLocalizedString(@"Toggles database field visibility.", @"Toggles database field visibility.");
}

@end
