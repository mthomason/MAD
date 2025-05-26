//
//  MADNavigationControllerIdentity.h
//  MAD Designer
//
//  Created by Michael on 1/4/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADNavigationControllerIdentity_h
#define MADNavigationControllerIdentity_h

typedef NS_ENUM(short, MADNavigationControllerType) {
	MADNavigationControllerTypeUnknown = 0,
	MADNavigationControllerTypeInformation,
	MADNavigationControllerTypeLicensing,
	MADNavigationControllerTypeNewDocument,
	MADNavigationControllerTypeToolbox,
	MADNavigationControllerTypeFontPicker,
	MADNavigationControllerTypeAggregateAdd,
	MADNavigationControllerTypeElementPicker,
	MADNavigationControllerTypeViewer,
	MADNavigationControllerTypeFileExplorer,
	MADNavigationControllerTypeDesigner,
	MADNavigationControllerTypeQuery,
	MADNavigationControllerTypeQueryVisualization
};

static inline NSString *NSStringFromMADNavigationControllerType(MADNavigationControllerType);
static inline NSString *NSStringFromMADNavigationControllerType(MADNavigationControllerType type) {
	switch (type) {
		case MADNavigationControllerTypeInformation: return @"MADNavigationControllerTypeInformation";
		case MADNavigationControllerTypeLicensing: return @"MADNavigationControllerTypeLicensing";
		case MADNavigationControllerTypeNewDocument: return @"MADNavigationControllerTypeNewDocument";
		case MADNavigationControllerTypeToolbox: return @"MADNavigationControllerTypeToolbox";
		case MADNavigationControllerTypeFontPicker: return @"MADNavigationControllerTypeFontPicker";
		case MADNavigationControllerTypeAggregateAdd: return @"MADNavigationControllerTypeAggregateAdd";
		case MADNavigationControllerTypeElementPicker: return @"MADNavigationControllerTypeElementPicker";
		case MADNavigationControllerTypeViewer: return @"MADNavigationControllerTypeViewer";
		case MADNavigationControllerTypeFileExplorer: return @"MADNavigationControllerTypeFileExplorer";
		case MADNavigationControllerTypeDesigner: return @"MADNavigationControllerTypeDesigner";
		case MADNavigationControllerTypeQuery: return @"MADNavigationControllerTypeQuery";
		default: return @"Unknown";
	}
}

@protocol MADNavigationControllerIdentify <NSObject>
	@property (readonly, nonatomic, assign) MADNavigationControllerType controllerType;
@end


#endif /* MADNavigationControllerIdentity_h */
