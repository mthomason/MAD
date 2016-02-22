//
//  UIStoryboard+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIStoryboard+InformationTable.h"

static NSString * const InformationTable        = @"MADStoryboardInformationTable";

@implementation UIStoryboard (InformationTable)

+ (instancetype)InformationTable {
    return [self storyboardWithName: InformationTable bundle:[NSBundle mainBundle]];
}

@end
