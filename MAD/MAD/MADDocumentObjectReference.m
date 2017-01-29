//
//  MADDocumentObjectReference.m
//  MAD
//
//  Created by Michael on 1/16/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectReference.h"
#import "RptqDocumentElement+CoreDataClass.h"
#import <Foundation/NSDictionary.h>

@interface MADDocumentObjectDataReference ()

    @property (readwrite, nonatomic, weak) NSObject <MADPrintPageRendererDataSourceProtocol> *datasource;
    @property (readwrite, nonatomic, strong) NSMutableDictionary <NSManagedObjectID *, MADocumentObjectAttributesText *> *fontDescriptors;

@end

@implementation MADDocumentObjectDataReference

- (void)dealloc {
    [_fontDescriptors removeAllObjects];
}

- (instancetype)initWithDataSource:(NSObject <MADPrintPageRendererDataSourceProtocol> *)datasource {
    if (self = [super init]) {
        
        self.datasource = datasource;
        
        NSMutableDictionary <NSManagedObjectID *, MADocumentObjectAttributesText *> *fontDescriptors;
        fontDescriptors = [[NSMutableDictionary <NSManagedObjectID *, MADocumentObjectAttributesText *>alloc] init];
        self.fontDescriptors = fontDescriptors;
    }
    return self;
}


- (id)copyWithZone:(NSZone *)zone {
    typeof(self) copy = [[self.class allocWithZone:zone] init];
    copy.item = _item;
    copy.detailRowId = _detailRowId;
    copy.pageIndex = _pageIndex;
    copy.datasource = _datasource;
    return copy;
}

@end
