//
//  MADStandard.h
//  MADExplorer
//
//  Created by Michael Thomason on 6/20/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADDocumentObjectTypeDescriptor_h
#define MAD_MADDocumentObjectTypeDescriptor_h

#import <Foundation/NSObject.h>

@interface MADStandard : NSObject

	+ (instancetype)newStandardStringForDouble:(double)d;
	+ (instancetype)newStandardStringForUnsignedLong:(unsigned long)ul;
	+ (instancetype)newStandardStringForFileSize:(unsigned long long)filesize;

@end

#endif
