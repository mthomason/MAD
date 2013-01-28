//
//  UITableViewCellTableName.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewCellTableName.h"
#import "Constants.h"

@implementation UITableViewCellTableName

@synthesize tableID = _tableID;
/*
- (void)dealloc {
    [super dealloc];
    if (_tableID != nil) [_tableID release];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {

        //[self setBackgroundView: nil];
        //[self setSelectedBackgroundView: nil];
        
    }
    return self;
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        //[self setBackgroundView: nil];
        //[self setSelectedBackgroundView: nil];
        
    }
    return self;
    
}


- (void)setBackgroundView:(UIView *)backgroundView {
    [super setBackgroundView: nil];
}

- (void)setSelectedBackgroundView:(UIView *)selectedBackgroundView {
    [super setSelectedBackgroundView: nil];
}
*/
//- (void)viewDidLoad {
//    [self setBackgroundView: nil];
//    [self setSelectedBackgroundView: nil];    
//}

+ (CGFloat)defaultHeight {
    return MNSTableViewCellTableNameHeightDefault;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

@end