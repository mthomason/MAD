//
//  MADFileExplorerView.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/20/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADFileExplorerView.h"
#import "MADWatermarkView.h"

@implementation MADFileExplorerView

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.backgroundView == nil) {
        id watermarkView = [[MADWatermarkView alloc] initWithFrame: self.bounds];
        self.backgroundView = watermarkView;
        self.backgroundColor = [UIColor lightGrayColor];
    }
}


@end
