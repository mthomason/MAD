//
//  MADFileExplorerView.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/20/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADFileExplorerView.h"
#import <UIKit/UIView.h>
#import <UIKit/UITapGestureRecognizer.h>
#import "MADWatermarkView.h"

@implementation MADFileExplorerView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
        id watermarkView = [[MADWatermarkView alloc] initWithFrame: self.bounds];
        self.backgroundView = watermarkView;
        self.backgroundColor = [UIColor lightGrayColor];
        self.scrollIndicatorInsets = self.contentInset;

    }
    return self;
}

@end
