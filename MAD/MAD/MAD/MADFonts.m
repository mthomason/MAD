//
//  MADFonts.m
//  MAD
//
//  Created by Michael Thomason on 2/29/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADFonts.h"
#import <UIKit/UIFont.h>

@interface MADFonts ()

@property (nonatomic, strong, readwrite) NSArray <NSString *> *familyNames;

@end

@implementation MADFonts

- (instancetype)init {
    if (self = [super init]) {
        
        NSArray *unsortedNames = [UIFont familyNames];
        NSArray *sortedNames = [unsortedNames sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        NSArray <NSString *> *familyNames = [NSArray arrayWithArray:sortedNames];
        self.familyNames = familyNames;

    }
    return self;
}

@end
