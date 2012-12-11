//
//  MTPair.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/10/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTPair : NSObject

- (id)initWithFormer:(id)former andLater:(id)later;

@property (nonatomic, retain) id former;
@property (nonatomic, retain) id latter;

@end