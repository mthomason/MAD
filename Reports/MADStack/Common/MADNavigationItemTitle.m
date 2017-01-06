//
//  MADNavigationItemTitle.m
//  MAD Designer
//
//  Created by Michael on 1/5/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADNavigationItemTitle.h"
#import "MADLabelTitle.h"

@interface MADNavigationItemTitle ()
    @property (nonatomic, strong) MADLabelTitle *labelTitle;
@end

@implementation MADNavigationItemTitle

- (instancetype)initWithTitle:(NSString *)title {
    if (self = [super initWithTitle:title]) {

        id labelTitle;

        labelTitle = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
        self.labelTitle = labelTitle;
        
        NSString *text = [[NSString alloc] initWithString:title];
        self.title = text;
        
    }
    return self;
}



@end
