//
//  MADSymbolReference.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Scrimpter_MADSymbolReference_h
#define MAD_Scrimpter_MADSymbolReference_h

#import <Foundation/Foundation.h>

@interface MADSymbolReference : NSObject

+ (id)symbolReferenceWithFilename:(NSString *)filename flags:(NSInteger)flags line:(NSInteger)line andColumns:(NSInteger)columns;

@end

#endif
