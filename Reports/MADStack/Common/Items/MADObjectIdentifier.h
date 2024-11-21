//
//  MADDocumentObjectPickerType.h
//  MAD Designer
//
//  Created by Michael Thomason on 7/9/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADObjectIdentifier_h
#define MAD_Designer_MADObjectIdentifier_h

#import <Foundation/NSObject.h>

@interface MADObjectIdentifier : NSObject

	@property (nonatomic, copy, readonly) NSString *identifier;
	@property (nonatomic, assign, readonly) NSUInteger serial;

	- (instancetype)initWithIdentifier:(NSString *)identifier andSerial:(NSUInteger)serial;

@end

#endif
