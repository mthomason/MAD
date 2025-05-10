//
//  MADQueryFullTableEnumerator.h
//  MAD
//
//  Created by Michael Thomason on 6/10/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADQueryFullTableEnumerator_h
#define Reports_MADQueryFullTableEnumerator_h

#import <Foundation/NSEnumerator.h>

@class RptqDocument;

@interface MADQueryFullTableEnumerator : NSEnumerator

	- (instancetype)initWithDocument:(RptqDocument *)document;

@end

#endif
