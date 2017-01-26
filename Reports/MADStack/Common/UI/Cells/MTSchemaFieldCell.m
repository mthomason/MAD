//
//  MTSchemaFieldCell.m
//  Reports
//
//  Created by Michael Thomason on 2/15/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTSchemaFieldCell.h"
#import <UIKit/UILabel.h>

@implementation MTSchemaFieldCell

+ (void)initialize {
    [super initialize];
    if (self == [MTSchemaFieldCell self]) {
        @autoreleasepool {
            UILabel <UIAppearance> *appearanceProxy;
            NSArray <Class <UIAppearanceContainer>> *classes;
            classes = [[NSArray alloc] initWithObjects: self, nil];
            appearanceProxy = [UILabel appearanceWhenContainedInInstancesOfClasses:classes];
            UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
            appearanceProxy.font = [font fontWithSize:8.0000f];
            font = nil;
        }
    }
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {

    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}


@end
