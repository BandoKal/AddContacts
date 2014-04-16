//
//  ALAssetsLibraryMock.h
//  CoreFramework
//
//  Created by Tregoning, Glen on 2/25/14.
//  Copyright (c) 2014 Asurion Mobile Applications. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import "ALAssetsGroupMock.h"

@interface ALAssetsLibraryMock : ALAssetsLibrary

// Input Parameters to writeImageDataToSavedPhotosAlbum:metadata:completionBlock:
@property (nonatomic, strong) NSData *writeInputImageData;
@property (nonatomic, strong) NSDictionary* writeInputMetaData;

// Input Parameters to writeVideoAtPathToSavedPhotosAlbum:(NSURL *)videoPathURL completionBlock:
@property (nonatomic, strong) NSURL *writeInputVideoPathURL;

// Completion block results to writeImageDataToSavedPhotosAlbum:metadata:completionBlock: /  writeVideoAtPathToSavedPhotosAlbum:(NSURL *)videoPathURL completionBlock:
@property (nonatomic, strong) NSURL *writeResultAssetURL;
@property (nonatomic, strong) NSError *writeResultError;

@property (nonatomic, assign) BOOL videoAtPathIsCompatible;

@property (nonatomic, strong) ALAssetsGroupMock *group;

// Input parameters to assetForURL:resultBlock:
@property (nonatomic, strong) NSURL *assetForURLInputURL;
@property (nonatomic, assign) BOOL assetForURLErrorOccurred;

// Completion block result to assetForURL:resultBlock:failureBlock
@property (nonatomic, strong) ALAsset *assetForURLResultAsset;
@property (nonatomic, strong) NSError *assetForURLFailureError;

@end
