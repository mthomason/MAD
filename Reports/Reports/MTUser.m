//
//  MTUser.m
//  MAD
//
//  Created by Michael Thomason on 3/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTUser.h"

@interface MTUser()

@property (nonatomic, retain) NSMutableDictionary *urlsDocuments;   //MAReportDocument stored by their NSURLS

@end

@implementation MTUser

- (id)init {
    self = [super init];
    if (self) {
        
        NSMutableDictionary *urls = [[NSMutableDictionary alloc] init];
        [self setUrlsDocuments:urls];
        [urls release];
        
    }
    return self;
}

@end
