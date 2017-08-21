//
//  MADReportSectionRepresentation.m
//  MAD
//
//  Created by Michael Thomason on 10/29/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADReportSectionRepresentation.h"
#import "MADReportSectionRowsRepresentation.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>
#import <MADFoundation/MADErrorUserInfo.h>

@interface MADReportSectionRepresentation ()

    @property (nonatomic, strong, getter=hasRows) NSMutableArray <__kindof MADReportSectionRowsRepresentation *> *rows;

@end

@implementation MADReportSectionRepresentation

@synthesize elementOffset = _elementOffset, characterOffset = _characterOffset;

- (void)dealloc {
    [_rows removeAllObjects];
}

- (instancetype)init {
    return [self initWithNumberOfRows:0];
}

- (instancetype)initWithNumberOfRows:(NSUInteger)capacity {
    if (self = [super init]) {
        NSMutableArray *rows = capacity > 0 ? [[NSMutableArray alloc] initWithCapacity:capacity] :
                                                [[NSMutableArray alloc] init];
        self.rows = rows;
    }
    return self;
}

- (void)addRow:(MADReportSectionRowsRepresentation *)row error:(NSError * __autoreleasing *)error {
    @try {
        [_rows addObject:row];
    } @catch (NSException *exception) {
        MADErrorUserInfo *userInfo = [[MADErrorUserInfo alloc] initWithTitle:@"Error"
                                                                  andMessage:@"Failed to add null value."];
        *error = [userInfo errorWithDomain:NSStringFromClass(self.class) code:49832];
    } @finally {
        
    }
}

- (NSUInteger)numberOfRows { return self.rows.count; }

#pragma mark - MADTextRepresentationProtocol

- (NSUInteger)characterCount {
    NSUInteger characterCount = 0;
    MADReportSectionRowsRepresentation *row;
    for (row in _rows) {
        characterCount += [row characterCount];
    }
    return characterCount;
}

- (NSUInteger)elementCount {
    NSUInteger elementCount = 0;
    MADReportSectionRowsRepresentation *row;
    for (row in _rows) {
        elementCount += [row elementCount];
    }
    return elementCount;
}

@end
