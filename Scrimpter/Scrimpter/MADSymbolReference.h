//
//  MADSymbolReference.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/18/14.
//  Copyright (c) 2024 Michael Thomason. All rights reserved.
//

#ifndef MAD_Scrimpter_MADSymbolReference_h
#define MAD_Scrimpter_MADSymbolReference_h

#import <Foundation/Foundation.h>

@interface MADSymbolReference : NSObject

@property (nonatomic, weak, readonly) NSString *symbol;

+ (id)symbolReferenceWithSymbol:(NSString *)symbol filename:(NSString *)filename flags:(NSInteger)flags line:(NSInteger)line andColumns:(NSInteger)columns;

@end

#endif
