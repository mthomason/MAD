//
//  UITableViewCellQueryGroup.m
//  Reports
//
//  Created by Michael Thomason on 2/2/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewCellQueryGroup.h"

@interface UITableViewCellQueryGroup ()

@property (nonatomic, retain) IBOutletCollection(NSLayoutConstraint) NSArray *bogusConstraints;

@end

@implementation UITableViewCellQueryGroup

- (void)dealloc {
    [_tableID release];
    [_bogusConstraints release];
    [super dealloc];
}

- (void)awakeFromNib {
    //[super awakeFromNib];
    
    /*
    
    for (NSLayoutConstraint *constraint in [self constraints]) {
        
        [self removeConstraint:constraint];
        
        id firstItem = [constraint firstItem] == self ? [self contentView] : [constraint firstItem];
        id seccondItem = [constraint secondItem] == self ? [self contentView] : [constraint secondItem];
        
        NSLayoutConstraint* contentViewConstraint = [NSLayoutConstraint constraintWithItem: firstItem
                                                                                 attribute: [constraint firstAttribute]
                                                                                 relatedBy: [constraint relation]
                                                                                    toItem: seccondItem
                                                                                 attribute: [constraint secondAttribute]
                                                                                multiplier: [constraint multiplier]
                                                                                  constant: [constraint constant]];
        
        [[self contentView] addConstraint:contentViewConstraint];
    }*/
    [super awakeFromNib];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        /*
        UIView *backView = [[UIView alloc] initWithFrame:CGRectZero];
        UIView *backView1 = [[UIView alloc] initWithFrame:CGRectZero];
		[backView setBackgroundColor: [UIColor clearColor]];
		[backView1 setBackgroundColor: [UIColor clearColor]];
        [self setBackgroundColor: [UIColor clearColor]];
		[self setBackgroundView: nil];
        [self setSelectedBackgroundView: nil];
        [backView release];
        [backView1 release];
*/
    }
    return self;
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
/*
        //UIView *backView = [[UIView alloc] initWithFrame:CGRectZero];
		//[backView setBackgroundColor: [UIColor clearColor]];
		//[self setBackgroundColor: [UIColor clearColor]];
		//[self setBackgroundView: backView];
        //[self setSelectedBackgroundView:backView];
        //[backView release];
        UIView *backView = [[UIView alloc] initWithFrame:CGRectZero];
        UIView *backView1 = [[UIView alloc] initWithFrame:CGRectZero];
		[backView setBackgroundColor: [UIColor clearColor]];
		[backView1 setBackgroundColor: [UIColor clearColor]];
        [self setBackgroundColor: [UIColor clearColor]];
		[self setBackgroundView: backView];
        [self setSelectedBackgroundView:backView1];
        [backView release];
        [backView1 release];*/
    }
    return self;
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

+ (CGFloat)defaultHeight {
    return 88.0000f;
}

@end