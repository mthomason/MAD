//
//  MADQueryVisualizationContentView.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/10/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryVisualizationContentView.h"

@implementation MADQueryVisualizationContentView

+ (void)initialize {
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
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        //self.contentMode = UIViewContentModeScaleAspectFit;
        //self.autoresizesSubviews = NO;
        //self.translatesAutoresizingMaskIntoConstraints = NO;
        //self.opaque = NO;
        //self.backgroundColor = [UIColor clearColor];
        NSLog(@"Mode: %ld", (long)self.contentMode);
        NSLog(@"AR %@", self.autoresizesSubviews ? @"YES" : @"NO");
        NSLog(@"TR %@", self.translatesAutoresizingMaskIntoConstraints ? @"YES" : @"NO");
        NSLog(@"OP %@", self.opaque ? @"YES" : @"NO");
        NSLog(@"BG %@", self.backgroundColor);
    }
    return self;
}

@end
