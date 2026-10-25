//
//  MADReportFormatterDataSourceProtocol.h
//  MAD
//
//  Created by Michael Thomason on 5/24/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADReportFormatterDataSourceProtocol_h
#define MADReportFormatterDataSourceProtocol_h

@protocol MADReportFormatterDataSource <NSObject>

	- (BOOL)cacheExist;
	- (NSEnumerator <NSDictionary *> *)enumeratorForReportData;
	- (NSDictionary *)dataForRow:(NSUInteger)cachedID;

@end

#endif /* MADReportFormatterDataSourceProtocol_h */
