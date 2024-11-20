//
//  MADTextPosition.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/29/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADTextPosition.h"

@implementation MADTextPosition

- (instancetype)init {
    if (self = [super init]) {
        self.page = 0;
        self.section = 0;
        self.row = 0;
        self.element = 0;
        self.offset = 0;
    }
    return self;
}

+ (instancetype)BeginningOfDocument {
    MADTextPosition *beginning = [[MADTextPosition alloc] init];
    return beginning;
}

@end
