//
//  MADDocumentObjectPickerType.h
//  MAD Designer
//
//  Created by Michael Thomason on 7/9/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADObjectIdentifier_h
#define MAD_Designer_MADObjectIdentifier_h

#import <Foundation/NSObject.h>

@interface MADObjectIdentifier : NSObject

@property (nonatomic, strong, readonly) NSString *identifier;
@property (nonatomic, assign, readonly) NSInteger tag;

- (instancetype)initWithIdentifier:(NSString *)identifier andTag:(NSInteger)tag;

@end

#endif
