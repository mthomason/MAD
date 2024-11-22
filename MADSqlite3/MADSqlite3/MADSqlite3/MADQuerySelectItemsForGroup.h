//
//  MADQuerySelectItemsForGroup.h
//  MAD
//
//  Created by Michael Thomason on 5/22/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADQuerySelectItemsForGroup_h
#define Reports_MADQuerySelectItemsForGroup_h

#import <MADAPI/MADQuery.h>

@interface MADQuerySelectItemsForGroup : MADQuery
	<MADQueryDataBindingProtocol, MADQueryColumnsProtocol>
@end

#endif
