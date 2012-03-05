//
//  UITableViewCellPredicate.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewCellQueryPredicate.h"

@implementation UITableViewCellQueryPredicate

@synthesize labelDetail, labelMain;

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        [self setBackgroundView: nil];
        [self setSelectedBackgroundView: nil];
        
    }
    return self;
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        [self setBackgroundView: nil];
        [self setSelectedBackgroundView: nil];
        
    }
    return self;
    
}

@end