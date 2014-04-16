//
//  ALAssetRepresentationMock.h
//  CoreFramework
//
//  Created by Tulseela, Naveen on 2/28/14.
//  Copyright (c) 2014 Asurion Mobile Applications. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

@interface ALAssetRepresentationMock : ALAssetRepresentation

@property (nonatomic, strong) NSURL *assetURL;
@property (nonatomic, strong) NSString *assetFileName;
@property (nonatomic) long long assetSize;
@property (nonatomic, strong) NSString *assetUTI;
@property (nonatomic,strong) NSData *bufferData;
@property (nonatomic, strong) NSError *error;
@end
