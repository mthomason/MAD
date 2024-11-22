//
//  MADUserDefault.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/16/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADUserDefault_h
#define MAD_Designer_MADUserDefault_h

#import <Foundation/NSObject.h>

@interface MADUserDefault : NSObject

	- (instancetype)initWithIdentifier:(NSString *)identifier;
	- (instancetype)initWithIdentifier:(NSString *)identifier shared:(BOOL)shared;

@end

#endif
