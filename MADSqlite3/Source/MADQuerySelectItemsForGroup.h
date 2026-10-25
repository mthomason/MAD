//
//  MADQuerySelectItemsForGroup.h
//  MAD
//
//  Created by Michael Thomason on 5/22/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADQuerySelectItemsForGroup_h
#define Reports_MADQuerySelectItemsForGroup_h

#import <MADAPI/MADQuery.h>

@interface MADQuerySelectItemsForGroup : MADQuery
	<MADQueryDataBindingProtocol, MADQueryColumnsProtocol>
@end

#endif
