//
//  MADStoryboard.m
//  MAD Designer
//
//  Created by Michael on 8/25/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADStoryboard.h"

@implementation MADStoryboard

+ (instancetype)newStoryboardQuery {
    id sb = [UIStoryboard storyboardWithName: @"MADQuery"
                                      bundle: [NSBundle mainBundle]];
    return sb;
}

@end
