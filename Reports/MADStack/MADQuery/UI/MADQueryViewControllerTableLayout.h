//
//  MADQueryViewControllerTableLayout.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/11/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADDesigner_MADQueryViewControllerTableLayout_h
#define MADDesigner_MADQueryViewControllerTableLayout_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MADQueryViewControllerTableLayout : NSObject

@property (nonatomic, readonly, copy) NSArray<NSNumber *> *sections;
@property (nonatomic, readonly, copy) NSDictionary<NSNumber *, NSString *> *headersBySection;
@property (nonatomic, readonly, copy) NSDictionary<NSNumber *, NSArray <NSNumber *> *> *rowCountsBySection;
@property (nonatomic, readonly, copy) NSDictionary<NSNumber *, NSArray <NSNumber *> *> *rowHeightsBySection;

- (instancetype)initWithNumberOfTables:(NSInteger)numberOfTables
					  reportingEnabled:(BOOL)reportingEnabled NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

- (NSArray <NSNumber *> *)sectionTypes;

@end

NS_ASSUME_NONNULL_END

#endif
