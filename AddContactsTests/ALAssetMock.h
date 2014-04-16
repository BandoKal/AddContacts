//
//  ALAssetMock.h
//  CoreFramework
//
//  Created by Tulseela, Naveen on 2/28/14.
//  Copyright (c) 2014 Asurion Mobile Applications. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import "ALAssetRepresentationMock.h"

@interface ALAssetMock : ALAsset

typedef NS_ENUM(NSInteger, ALAssetMockType) {
    ALAssetMockType_Photo,
    ALAssetMockType_Video,
    ALAssetMockType_Unknown
};
@property (nonatomic, assign) ALAssetMockType assetType;
@property (nonatomic, strong) ALAssetRepresentationMock *defaultRepresentation;
@end
