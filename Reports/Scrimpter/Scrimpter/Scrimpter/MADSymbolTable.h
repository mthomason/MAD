//
//  MADSymbolTable.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MADSymbol, MADSymbolReference;

@interface MADSymbolTable : NSObject

- (void)addSymbolReference:(NSString *)symbol reference:(MADSymbolReference *)symbolReference;
- (MADSymbol *)symbolForString:(NSString *)symbol;

@end
