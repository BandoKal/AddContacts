//
//  ALAssetsGroupMock.h
//  CoreFramework
//
//  Created by Tulseela, Naveen on 2/28/14.
//  Copyright (c) 2014 Asurion Mobile Applications. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

typedef NS_ENUM(NSInteger, ALAssetsGroupMockType) {
    ALAssetsGroupMockType_Album
};

extern NSString *const ALAssetsGroupPropertyName;

@interface ALAssetsGroupMock : ALAssetsGroup

@property (nonatomic, strong) NSMutableArray *assets;
@property (nonatomic, strong) NSString *ALAssetsGroupPropertyName;

@end
