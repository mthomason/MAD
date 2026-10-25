//
//  MADSymbol.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/18/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Scrimpter_MADSymbol_h
#define MAD_Scrimpter_MADSymbol_h

#import <Foundation/Foundation.h>

@class MADSymbol, MADSymbolReference, MADValue;

extern MADSymbolReference *(^ScrimptSymbolReference)(NSString *symbol, NSString *filename, NSInteger flags, NSInteger line, NSInteger columns);
extern id (^ScrimptData)(NSString *key);    //For gettting values from dictionary
extern MADSymbol *(^ScrimptSymbol)(NSString *key);
extern void (^Scrimpted)(BOOL success, id result, NSError *error);

@interface MADSymbol : NSObject

@property (nonatomic, strong) MADValue *mvalue;

- (id)initWithName:(NSString *)name;
- (void)addReference:(MADSymbolReference *)symbolReference;

@end

#endif
