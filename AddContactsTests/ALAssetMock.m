//
//  ALAssetMock.m
//  CoreFramework
//
//  Created by Tulseela, Naveen on 2/28/14.
//  Copyright (c) 2014 Asurion Mobile Applications. All rights reserved.
//

#import "ALAssetMock.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation ALAssetMock

- (id)valueForProperty:(NSString *)property {
    if ([property compare:ALAssetPropertyType] == NSOrderedSame){
        NSString *propertyType = nil;
        switch (self.assetType) {
            case ALAssetMockType_Photo:
                propertyType = ALAssetTypePhoto;
                break;
            case ALAssetMockType_Video:
                propertyType = ALAssetTypeVideo;
                break;
            case ALAssetMockType_Unknown:
                propertyType = ALAssetTypeUnknown;
                break;
            default:
                break;
        }
        return propertyType;
    }
    return nil;
}

@end
