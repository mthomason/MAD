//
//  Scrimpter.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/16/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "Scrimpter.h"
#import "MessageBlocks.h"

@interface Scrimpter ()

@end

@implementation Scrimpter

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

    ScrimptData = ^id(NSString *key) {
        return [[self datasource] dataForkey:key];
    };
    
    YY_BUFFER_STATE buffer = [self scan:scrimpt];
    Scrimpted = ^(BOOL success, id result, NSError *error) {
        completion(success, result, error);
    };
    [self parse];
    [self cleanup:buffer];
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
