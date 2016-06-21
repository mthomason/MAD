//
//  NSAttributedString+FileExplorer.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/20/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_NSAttributedString__FileExplorer_h
#define Reports_NSAttributedString__FileExplorer_h

#import <Foundation/NSAttributedString.h>

@interface NSAttributedString (FileExplorer)

    + (instancetype)newAttributedStringCaptionWithText:(NSString *)text;

@end

#endif
