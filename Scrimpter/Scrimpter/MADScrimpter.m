//
//  Scrimpter.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/16/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADScrimpter.h"
#import "MADSymbol.h"
#import "MADSymbolTable.h"
#import "MADSymbolReference.h"

MADSymbolTable *(^ScrimptSymbolTable)();

@interface MADScrimpter ()

@property (nonatomic, strong) MADSymbolTable *symbolTable;

@end

@implementation MADScrimpter

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)run:(NSString *)scrimpt {
    [self run:scrimpt completion:^(BOOL success, id result, NSError *error) {
        NSLog(@"Success %d %@ %@", success, result, error);
    }];
}

- (void)run:(NSString *)scrimpt completion:(void (^)(BOOL success, id result, NSError *error))completion {
    
    if ([scrimpt length] > 0) {

        MADSymbolTable *table = [MADSymbolTable new];
        [self setSymbolTable:table];
        
        ScrimptData = ^id(NSString *key) {
            return [[self datasource] dataForkey:key];
        };
        
        ScrimptSymbol = ^id(NSString *key) {
            return [[self symbolTable] symbolForString:key];
        };

        ScrimptSymbolReference = ^(NSString *symbol, NSString *filename, NSInteger flags, NSInteger line, NSInteger column) {
            MADSymbolReference *symbolReference = [MADSymbolReference symbolReferenceWithSymbol:symbol filename:filename flags:flags line:line andColumns:column];
            return [[self symbolTable] addSymbolReference:symbol reference:symbolReference];
        };
        
        ScrimptSymbolTable = ^MADSymbolTable *() {
            return [self symbolTable];
        };
        
        YY_BUFFER_STATE buffer = [self scan:scrimpt];
        Scrimpted = ^(BOOL success, id result, NSError *error) {
            completion(success, result, error);
        };
        [self parse];
        [self cleanup:buffer];

    } else {
        completion(YES, nil, nil);  //Empty is valid, but does nothing.
    }

}

- (YY_BUFFER_STATE)scan:(NSString *)scrimpt {
    const char *cscrimpt = [scrimpt cStringUsingEncoding:NSUTF8StringEncoding];
    return yy_scan_string(cscrimpt);
}

- (BOOL)parse {
    return yyparse() == 0;
}

- (void)cleanup:(YY_BUFFER_STATE)buffer {
    yy_delete_buffer(buffer);
}

@end
