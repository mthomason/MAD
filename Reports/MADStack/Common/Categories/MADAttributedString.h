//
//  NSAttributedString+Logo.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/7/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/NSAttributedString.h>

@interface MADAttributedString : NSAttributedString

+ (instancetype)newAttributedStringLogoForTitle:(NSString *)title;
+ (instancetype)newAttributedStringEverydayAppsOnTwitter;
+ (instancetype)newAttributedStringTwitter;
+ (instancetype)newAttributedStringFollowUsOnTwitter;

@end
