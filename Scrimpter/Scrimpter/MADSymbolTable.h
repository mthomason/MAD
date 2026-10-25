//
//  MADSymbolTable.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/18/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
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
