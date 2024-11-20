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
    MADNavigationControllerTypeQuery
};

@protocol MADNavigationControllerIdentify <NSObject>

    @property (readonly, nonatomic, assign) MADNavigationControllerType controllerType;

@end


#endif /* MADNavigationControllerIdentity_h */
