//
//  MADExplorerCaption.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/20/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADExplorer_MADExplorerCaption_h
#define MADExplorer_MADExplorerCaption_h

#import <Foundation/NSAttributedString.h>

@interface MADExplorerCaption : NSAttributedString

	+ (instancetype)newExplorerCaption:(NSString *)text;

@end

#endif
