//
//  MADSymbolTable.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/18/14.
//  Copyright (c) 2024 Michael Thomason. All rights reserved.
//

#ifndef MAD_Scrimpter_MADSymbolTable_h
#define MAD_Scrimpter_MADSymbolTable_h

#import <Foundation/Foundation.h>
@class MADSymbol, MADSymbolReference;

@interface MADSymbolTable : NSObject

- (MADSymbolReference *)addSymbolReference:(NSString *)symbol reference:(MADSymbolReference *)symbolReference;
- (MADSymbol *)symbolForString:(NSString *)symbol;

@end

#endif
