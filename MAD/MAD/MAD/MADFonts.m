//
//  MADFonts.m
//  MAD
//
//  Created by Michael Thomason on 2/29/16.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#import "MADFonts.h"
#import <UIKit/UIFont.h>

@interface MADFonts ()

@property (nonatomic, strong, readwrite) NSArray <NSString *> *familyNames;

@end

@implementation MADFonts

- (instancetype)init {
	if (self = [super init]) {
		self.familyNames = [[UIFont familyNames] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	}
	return self;
}

@end
