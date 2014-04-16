//
//  ALAssetsLibraryMock.m
//  CoreFramework
//
//  Created by Tregoning, Glen on 2/25/14.
//  Copyright (c) 2014 Asurion Mobile Applications. All rights reserved.
//

#import "ALAssetsLibraryMock.h"
#import "ALAssetMock.h"

@implementation ALAssetsLibraryMock

- (id)init {
    self = [super init];
    if (self) {
        self.videoAtPathIsCompatible = YES;
    }
    return self;
}

- (void)writeImageDataToSavedPhotosAlbum:(NSData *)imageData
                                metadata:(NSDictionary *)metadata
                         completionBlock:(ALAssetsLibraryWriteImageCompletionBlock)completionBlock {
    self.writeInputImageData = imageData;
    self.writeInputMetaData = metadata;
    completionBlock(self.writeResultAssetURL, self.writeResultError);
}

-(void)writeImageToSavedPhotosAlbum:(CGImageRef)imageRef
                        orientation:(ALAssetOrientation)orientation
                    completionBlock:(ALAssetsLibraryWriteImageCompletionBlock)completionBlock {
    self.writeResultAssetURL = [NSURL URLWithString: @"test_URL"];
    completionBlock(self.writeResultAssetURL, self.writeResultError);
}

- (void)writeVideoAtPathToSavedPhotosAlbum:(NSURL *)videoPathURL
                           completionBlock:(ALAssetsLibraryWriteVideoCompletionBlock)completionBlock {
    self.writeInputVideoPathURL = videoPathURL;
    completionBlock(self.writeResultAssetURL, self.writeResultError);
}

- (BOOL)videoAtPathIsCompatibleWithSavedPhotosAlbum:(NSURL *)videoPathURL {
    return self.videoAtPathIsCompatible;
}

- (void)enumerateGroupsWithTypes:(ALAssetsGroupType)types
                      usingBlock:(ALAssetsLibraryGroupsEnumerationResultsBlock)enumerationBlock
                    failureBlock:(ALAssetsLibraryAccessFailureBlock)failureBlock {
    BOOL stop;
    self.group.ALAssetsGroupPropertyName = @"Test Photos!";
    enumerationBlock(self.group, &stop);
    enumerationBlock(nil, &stop);
}

- (void)assetForURL:(NSURL *)assetURL
        resultBlock:(ALAssetsLibraryAssetForURLResultBlock)resultBlock
       failureBlock:(ALAssetsLibraryAccessFailureBlock)failureBlock {
    self.assetForURLInputURL = self.writeResultAssetURL;
    self.assetForURLResultAsset = [[ALAssetMock alloc]init];
    if (self.assetForURLErrorOccurred) {
        failureBlock(self.assetForURLFailureError);
    } else {
        resultBlock(self.assetForURLResultAsset);
    }
}

@end
