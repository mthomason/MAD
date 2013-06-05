//
//  UITableViewCellPredicate.m
//  Reports
//
//  Created by Michael Thomason on 2/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTTableViewCellQueryPredicate.h"

@implementation MTTableViewCellQueryPredicate

- (void)dealloc {
    [_labelMain release];
    [_labelDetail release];
    [_labelOpperator release];
    [_tableID release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
    }
    return self;
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

@end