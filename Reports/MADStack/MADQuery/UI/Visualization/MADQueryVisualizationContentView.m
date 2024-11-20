//
//  MADQueryVisualizationContentView.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/10/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADQueryVisualizationContentView.h"

@implementation MADQueryVisualizationContentView

/*+ (void)initialize {
    [super initialize];
    if (self == [MADQueryVisualizationContentView self]) {
        @autoreleasepool {
            //UILabel <UIAppearance> *appearanceProxy;
            //NSArray <Class <UIAppearanceContainer>> *classes;
            //classes = [[NSArray alloc] initWithObjects: [MTTitleView class], nil];
            //appearanceProxy = [UILabel appearanceWhenContainedInInstancesOfClasses:classes];
            //appearanceProxy.textColor = [UIColor whiteColor];
            //UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
            //appearanceProxy.font = [font fontWithSize:12.0000f];
            //font = nil;
            [MADQueryVisualizationContentView appearance].opaque = NO;
            [MADQueryVisualizationContentView appearance].backgroundColor = [UIColor clearColor];
            [MADQueryVisualizationContentView appearance].translatesAutoresizingMaskIntoConstraints = NO;
            [MADQueryVisualizationContentView appearance].autoresizesSubviews = NO;
            [MADQueryVisualizationContentView appearance].contentMode = UIViewContentModeScaleAspectFit;
            
        }
    }
}*/

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.opaque = NO;
        //self.backgroundColor = [UIColor redColor];
        //self.alpha = 0.3000f;
        [self setAutoresizingMask: UIViewAutoresizingNone];
        [self setTranslatesAutoresizingMaskIntoConstraints: NO];
        
        self.autoresizesSubviews = NO;
        self.contentMode = UIViewContentModeScaleAspectFit;
    }
    return self;
}

@end
