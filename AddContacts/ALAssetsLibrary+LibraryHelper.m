//
//  ALAssetsLibrary+LibraryHelper.m
//  AddContacts
//
//  Created by Jason Bandy on 4/16/14.
//  Copyright (c) 2014 Jason Bandy. All rights reserved.
//

#import "ALAssetsLibrary+LibraryHelper.h"

@implementation ALAssetsLibrary (LibraryHelper)

#pragma mark private class methods

-(void)addAssetURL:(NSURL*)assetURL toAlbum:(NSString*)albumName withCompletionBlock:(SaveImageCompletion)completionBlock
{
    __block BOOL albumWasFound = NO;
    
    //search all photo albums in the library
    [self enumerateGroupsWithTypes:ALAssetsGroupAlbum
                        usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                            
                            //compare the names of the albums
                            if ([albumName compare: [group valueForProperty:ALAssetsGroupPropertyName]]==NSOrderedSame) {
                                
                                //target album is found
                                albumWasFound = YES;
                                
                                //get a hold of the photo's asset instance
                                [self assetForURL:assetURL
                                      resultBlock:^(ALAsset *asset) {
                                          
                                          //add photo to the target album
                                          [group addAsset: asset];
                                          
                                          //run the completion block
                                          completionBlock(nil);
                                          
                                      } failureBlock: completionBlock];
                                
                                return;
                            }
                            
                            if (group==nil && albumWasFound==NO) {
                                
                                __weak ALAssetsLibrary* weakLibrary = self;
                                
                                //create new assets album
                                [self addAssetsGroupAlbumWithName:albumName
                                                      resultBlock:^(ALAssetsGroup *group) {
                                                          
                                                          [weakLibrary assetForURL: assetURL
                                                                       resultBlock:^(ALAsset *asset) {
                                                                           [group addAsset: asset];
                                                                           
                                                                           completionBlock(nil);
                                                                           
                                                                       } failureBlock: completionBlock];
                                                          
                                                      } failureBlock: completionBlock];
                                
                                return;
                            }
                            
                        } failureBlock: completionBlock];
    
}


#pragma mark - Public Helpers

-(void)saveImage:(UIImage*)image toAlbum:(NSString*)albumName withCompletionBlock:(SaveImageCompletion)completionBlock{
    
    [self writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
        
        if (error != nil) {
            completionBlock(error);
            return;
        }

        completionBlock(nil);
        // Calling Add Asset to Album appears to cause a memory leak issue..
//        [self addAssetURL:assetURL
//                  toAlbum:albumName
//      withCompletionBlock:completionBlock];
    }];
    
}

@end
