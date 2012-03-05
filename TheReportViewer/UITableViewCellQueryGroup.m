//
//  UITableViewCellQueryGroup.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewCellQueryGroup.h"

@implementation UITableViewCellQueryGroup

@synthesize labelDetail, labelMain;

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        UIView *backView = [[UIView alloc] initWithFrame:CGRectZero];
        UIView *backView1 = [[UIView alloc] initWithFrame:CGRectZero];
		[backView setBackgroundColor: [UIColor clearColor]];
		[backView1 setBackgroundColor: [UIColor clearColor]];
        [self setBackgroundColor: [UIColor clearColor]];
		[self setBackgroundView: nil];
        [self setSelectedBackgroundView: nil];
        [backView release];
        [backView1 release];

    }
    return self;
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {

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
        [backView1 release];
    }
    return self;
    
}

@end