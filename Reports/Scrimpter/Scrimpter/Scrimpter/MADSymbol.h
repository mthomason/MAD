//
//  MADSymbol.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MADSymbolReference.h"

@interface MADSymbol : NSObject

- (id)initWithName:(NSString *)name;
- (void)addReference:(MADSymbolReference *)symbolReference;

@end
