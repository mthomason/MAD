//
//  Scrimpter.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/16/14.
//  Copyright (c) 2024 Michael Thomason. All rights reserved.
//

#ifndef MAD_Scrimpter_Scrimpter_h
#define MAD_Scrimpter_Scrimpter_h


#import <Foundation/Foundation.h>
#import "MADSymbol.h"

@class  MADSymbolTable;

extern MADSymbolTable *(^ScrimptSymbolTable)();

#ifndef FLEXINT_H
 
    typedef struct yy_buffer_state *YY_BUFFER_STATE;
    YY_BUFFER_STATE  yy_scan_string(const char *s);
 
    int yyparse();
    void yy_delete_buffer(YY_BUFFER_STATE buf);
 
#endif

@protocol ScrimpterDataSource <NSObject>
- (id)dataForkey:(NSString *)key;
@end

@interface MADScrimpter : NSObject

@property (nonatomic, weak) IBOutlet id <ScrimpterDataSource> datasource;

- (void)run:(NSString *)scrimpt;
- (void)run:(NSString *)scrimpt completion:(void (^)(BOOL success, id result, NSError *error))completion;

@end

#endif
