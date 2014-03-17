//
//  MTViewTableHeader.h
//  Reports
//
//  Created by Michael Thomason on 1/27/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTViewTableHeader_h
#define Reports_MTViewTableHeader_h

#import <UIKit/UIKit.h>

@interface MTViewTableHeader : UIView

- (id)initWithFrame:(CGRect)frame;

@property (nonatomic, retain) UIButton *buttonAdd;
@property (nonatomic, retain) UILabel *labelTitle;

@end

#endif
