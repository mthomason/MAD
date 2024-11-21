//
//  MADDesignerElementTextView.h
//  MAD Designer
//
//  Created by Michael on 5/22/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADDesignerElementTextView_h
#define Reports_MADDesignerElementTextView_h

#import "MADDesignerElementView.h"
#import <MAD/MADHorizontalAlignmentType.h>
#import <MAD/MADVerticalAlignmentType.h>

@protocol MADTextElementProtocol <NSObject>

	- (void)updateHorizontalAlignment:(MADHorizontalAlignment)horizontal;
	- (void)updateVerticalAlignment:(MADVerticalAlignment)vertical;
	- (void)updateFontName:(NSString *)fontname
				  fontSize:(double)fontsize
					  bold:(BOOL)bold
					italic:(BOOL)italic;
	- (void)updateFontSize:(double)fontsize;
	- (void)updateFontName:(NSString *)fontname;
	- (void)updateSetStrikethrough:(BOOL)strikethrough;
	- (void)updateSetUnderline:(BOOL)underline;

@end

@interface MADDesignerElementTextView : MADDesignerElementView
	<MADTextElementProtocol>

	@property (nonatomic, readwrite, strong) NSMutableAttributedString *displayObject;

@end

#endif
