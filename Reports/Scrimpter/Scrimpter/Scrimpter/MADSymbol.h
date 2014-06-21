//
//  MADSymbol.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Scrimpter_MADSymbol_h
#define MAD_Scrimpter_MADSymbol_h

#import <Foundation/Foundation.h>
#import "MADSymbolReference.h"

@class MADSymbol;

extern MADSymbol *(^ScrimptSymbolReference)(NSString *symbol, NSString *filename, NSInteger flags, NSInteger line, NSInteger columns);
extern id (^ScrimptData)(NSString *key);
extern void (^Scrimpted)(BOOL success, id result, NSError *error);

typedef NS_ENUM(NSInteger, SCVarableType) {
    SCVarableTypeDouble,
    SCVarableTypeString,
};

@interface MADSymbol : NSObject

@property (nonatomic, strong) id value;
@property (nonatomic, assign) SCVarableType type;

- (id)initWithName:(NSString *)name;
- (void)addReference:(MADSymbolReference *)symbolReference;

@end

#endif
