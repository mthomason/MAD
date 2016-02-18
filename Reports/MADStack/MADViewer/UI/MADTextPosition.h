//
//  MADTextPosition.h
//  MAD Designer
//
//  Created by Michael Thomason on 10/29/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MADTextPosition : UITextPosition

@property (nonatomic, assign) NSUInteger page;
@property (nonatomic, assign) NSUInteger section;
@property (nonatomic, assign) NSUInteger row;
@property (nonatomic, assign) NSUInteger element;
@property (nonatomic, assign) NSUInteger offset;

+ (instancetype)BeginningOfDocument;

@end

