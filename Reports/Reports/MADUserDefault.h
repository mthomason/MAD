//
//  MADUserDefault.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/16/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MADUserDefault : NSObject

- (instancetype)initWithIdentifier:(NSString *)identifier;
- (instancetype)initWithIdentifier:(NSString *)identifier shared:(BOOL)shared;

@end
