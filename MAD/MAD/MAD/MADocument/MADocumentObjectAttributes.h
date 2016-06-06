//
//  MADocumentObjectAttributes.h
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/NSObject.h>

@class RptqDocumentObject;

@interface MADocumentObjectAttributes : NSObject

    - (nullable instancetype)init NS_UNAVAILABLE;
    - (nullable instancetype)initWithObject:(RptqDocumentObject * _Nonnull)object
                                                                    NS_DESIGNATED_INITIALIZER;

@end
