//
//  MADQueryVisualizationCacheManager.m
//  MAD Designer
//
//  Created by Michael on 3/8/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADQueryVisualizationCacheManager.h"
#import "MADHierarchicalDisplayModel.h"
#import "MADQueryVisualizationModel.h"
#import "MADManagedObjectViewProtocol.h"
#import "MADHierarchicalGroupingNodeProtocol.h"
#import "MADHierarchicalChildViewDefination.h"
#import "MADOperationArchiveData.h"
#import "MADCacheManager.h"
#import <MADFoundation/madlog.h>

#import <MADDataStructures/MTVertex.h>
#import <MADDataStructures/MTLinkedList.h>
#import <MADDataStructures/MTPair.h>

#import <Foundation/NSValue.h>
#import <Foundation/NSException.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSKeyedArchiver.h>

@interface MADQueryVisualizationCacheManager ()

@property (readwrite, nonatomic, strong) NSURL *url;
@property (readwrite, nonatomic, strong) MADHierarchicalDisplayModel *cacheData;

@end

@implementation MADQueryVisualizationCacheManager

- (instancetype)initWithURL:(NSURL *)url {
	if (self = [super init]) {
		self.url = url.copy;
	}
	return self;
}

#pragma mark -
#pragma mark Cache Operations

- (void)updateCacheWithQuery:(MADModelQuery *)query contentOffset:(CGPoint)contentOffset
				   zoomScale:(CGFloat)zoomScale center:(CGPoint (^)(NSNumber *))center {
	
	MADQueryVisualizationModel *queryDef = [[MADQueryVisualizationModel alloc] initWithQuery:query];
	MTLinkedList *topologicallySortedTables = queryDef.topologicallySortedTables;
	
	MADHierarchicalDisplayModel *cacheData = [[MADHierarchicalDisplayModel alloc] initWithNumberOfTables:[topologicallySortedTables count]];
	cacheData.scrollViewContentOffset = contentOffset;
	cacheData.scrollViewZoomScale = zoomScale;
	
	for (MTPair *pair in queryDef.topologicallySortedTables) {
		
		MTVertex *tableIDVertext = (MTVertex *)pair.former;
		if (tableIDVertext.object != nil) {
			
			NSNumber *tableID = (NSNumber *)tableIDVertext.object;
			
			MADHierarchicalChildViewDefination *tableModel = [[MADHierarchicalChildViewDefination alloc] init];
			tableModel.center = center(tableID);
			tableModel.root = [queryDef.startingPoints containsObject: tableID];
			[cacheData addTableDefination:tableModel forObjectID: tableID.longLongValue];
		}
	}
	self.cacheData = cacheData;
}

- (void)archiveCache {
	MADOperationArchiveData *operation = [[MADOperationArchiveData alloc] initWithURL: self.url
																			andObject: self.cacheData];
	[[MADCacheManager sharedManager] addOperation:operation];
}

- (MADHierarchicalDisplayModel *)loadCache {

	MADHierarchicalDisplayModel *result;
	NSError *error = nil;
	NSData *data = [[NSData alloc] initWithContentsOfURL: self.url options: NSDataReadingUncached error: &error];
	if (error != nil) {
		os_log_info(GetDesignerLog(), "%s: %@", __PRETTY_FUNCTION__, error);
		NSError *removeItemError = nil;
		BOOL removeItemStatus = [[NSFileManager defaultManager] removeItemAtURL: self.url
																		  error: &removeItemError];
		if (!removeItemStatus && removeItemError != nil) {
			os_log_error(GetDesignerLog(), "%s: %@", __PRETTY_FUNCTION__, removeItemError);
		}
		result = nil;
	} else {
		@try {
			result = [NSKeyedUnarchiver unarchivedObjectOfClass: [MADHierarchicalDisplayModel class]
													   fromData: data
														  error: nil];
		} @catch (NSException *exception) {
			NSError *cleanup = nil;
			BOOL cleanupStatus = [[NSFileManager defaultManager] removeItemAtURL: self.url error: &cleanup];
			if (!cleanupStatus && cleanup != nil) {
				os_log_error(GetDesignerLog(), "%s: %@", __PRETTY_FUNCTION__, cleanup);
			}
		} @finally {
			if (![result isKindOfClass:[MADHierarchicalDisplayModel class]] || result == nil) {
				NSError *errorRemove = nil;
				BOOL removeStatus = [[NSFileManager defaultManager] removeItemAtURL:self.url error:&errorRemove];
				if (!removeStatus && errorRemove != nil) {
					os_log_error(GetDesignerLog(), "%s: %@", __PRETTY_FUNCTION__, errorRemove);
				}
				result = nil;
			}
		}
	}
	return result;
}

@end
