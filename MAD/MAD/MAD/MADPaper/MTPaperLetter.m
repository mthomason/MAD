//
//  MTPaperLetter.m
//  MAD
//
//  Created by Michael Thomason on 3/5/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTPaperLetter.h"

@implementation MTPaperLetter

- (instancetype)init {
    if (self = [super init]) { }
    return self;
}

- (CGSize)paperSize { return [MTPaperLetter size]; }
+ (CGSize)size { return [MTPaper sizeLetter]; }

- (MTPaperType)paperType { return [MTPaperLetter type]; }
+ (MTPaperType)type { return MTPaperTypeLetter; };

@end
