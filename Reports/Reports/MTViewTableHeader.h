//
//  MTViewTableHeader.h
//  Reports
//
//  Created by Michael Thomason on 1/27/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIColor+EverydayApps.h"

@interface MTViewTableHeader : UIView

- (id)initWithFrame:(CGRect)frame;

@property (nonatomic, retain) UIButton *buttonAdd;
@property (nonatomic, retain) UILabel *labelTitle;

@end