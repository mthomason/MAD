//
//  CoreDataTableViewController.m
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "UIViewTableSectionHeaderDatabaseTable.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+EverydayApps.h"

@interface UIViewTableSectionHeaderDatabaseTable ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *disclosureButton;
@property (nonatomic, assign) NSInteger section;
@property (nonatomic, weak) id <SectionHeaderViewDelegate> delegate;

@end

@implementation UIViewTableSectionHeaderDatabaseTable


- (instancetype)initWithFrame:(CGRect)frame title:(NSString*)title section:(NSInteger)sectionNumber delegate:(id <SectionHeaderViewDelegate>)delegate {
    
    self = [super initWithFrame:frame];
    
    if (self) {
        
        // Set up the tap gesture recognizer.
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleOpen:)];
        [self addGestureRecognizer:tapGesture];
        
        self.delegate =  delegate;
        [self setUserInteractionEnabled: YES];
        
        [self setSection: sectionNumber];
        CGRect titleLabelFrame = [self bounds];
        titleLabelFrame.origin.x += 35.00000f;
        titleLabelFrame.size.width -= 35.0000f;
        CGRectInset(titleLabelFrame, 0.0000f, 5.0000f);

        UILabel *label = [[UILabel alloc] initWithFrame:titleLabelFrame];
        [label setText: title];
        [label setFont: [UIFont boldSystemFontOfSize:17.0000f]];
        [label setTextColor: [UIColor tintColorBlue]];
        label.backgroundColor =  [UIColor clearColor];
        [self addSubview:label];
        [self setTitleLabel: label];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0.0000f, 5.0000f, 35.0000f, 35.0000f);
        [button setImage:[UIImage imageNamed:@"MADImageCarat"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"MADImageCaratOpen"] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(toggleOpen:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        [self setDisclosureButton: button];
        
        self.backgroundColor = [UIColor groupTableViewBackgroundColor];
    }
    
    return self;
}

- (IBAction)toggleOpen:(id)sender {
    [self toggleOpenWithUserAction:YES];
}


- (void)toggleOpenWithUserAction:(BOOL)userAction {
    
    [[self disclosureButton] setSelected: ![[self disclosureButton] isSelected]];
    
    if (userAction) {
        if ([[self disclosureButton] isSelected]) {
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
    [[self titleLabel] setTextColor:[UIColor whiteColor]];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    [[self titleLabel] setTextColor:[UIColor tintColorBlue]];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    [[self titleLabel] setTextColor:[UIColor tintColorBlue]];
}


@end
