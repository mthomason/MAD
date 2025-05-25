//
//  MADStandard.h
//  MADExplorer
//
//  Created by Michael Thomason on 6/20/16.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADDocumentObjectTypeDescriptor_h
#define MAD_MADDocumentObjectTypeDescriptor_h

#import <Foundation/NSObject.h>

@interface MADStandard : NSObject

+ (NSString *)standardStringForFileSize:(unsigned long long)filesize;

@end

#endif
