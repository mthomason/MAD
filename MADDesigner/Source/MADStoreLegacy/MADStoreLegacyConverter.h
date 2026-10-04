//
//  MADStoreLegacyConverter.h
//  MAD Designer
//
//  Copyright © 2026 Everyday Apps LLC. All rights reserved.
//
//  The implementation the MAD framework's MADLegacyStoreConversion registry finds:
//  the document asks for a converter, and this answers with the compiled Core Data
//  model and MADStoreConverter.  It registers itself in +load, so any process that
//  links this source (the app, the CLI, the test bundle) can open a legacy document.
//

#ifndef MAD_MADStoreLegacyConverter_h
#define MAD_MADStoreLegacyConverter_h

#import <Foundation/Foundation.h>

#import <MAD/MADLegacyStoreConversion.h>

NS_ASSUME_NONNULL_BEGIN

@interface MADStoreLegacyConverter : NSObject <MADDocumentLegacyStoreConverting>
@end

NS_ASSUME_NONNULL_END

#endif
