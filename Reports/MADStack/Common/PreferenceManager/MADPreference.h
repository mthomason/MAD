//
//  MADPreference.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/17/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADPreference_h
#define MAD_Designer_MADPreference_h

#import <Foundation/NSObject.h>

@interface MADPreference : NSObject

    - (instancetype)initWithKey:(NSString *)key;
    - (instancetype)initWithKey:(NSString *)key allowCloud:(BOOL)allowCloud encrypt:(BOOL)encrypt;

@end

#endif
