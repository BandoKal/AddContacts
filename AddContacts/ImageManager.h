//
//  ImageManager.h
//  AddContacts
//
//  Created by Locke, Jamaal on 5/15/14.
//  Copyright (c) 2014 Jason Bandy. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ALAssetsLibrary;

#pragma mark Error Variables
NSString *const BCGimageManipulationErrorDomain;

typedef NS_ENUM(NSInteger, BCGImageManipulationErrorCode) {
    BCGimageManipulationErrorCode_InvalidImageAdded,
    BCGImageManipulationErrorCode_TimeoutDuringImageImport,
};

#pragma mark Image Manager Delegate
@protocol ImageManagerDelegate <NSObject>

@optional
-(void)currentProgress:(NSUInteger)currentProgress ofTotal:(NSUInteger)total;
-(void)imageOperationCompletedSuccessfully;
-(void)imageOperationFailedPartiallyWithError:(NSError *)error onObject:(id)failedObject;
-(void)imageOperationFailedCompletelyWithError:(NSError *)error;

@end


@interface ImageManager : NSObject

-(instancetype)init __attribute__((unavailable("use initWithAssetsLibrary:delegate: instead")));
-(instancetype)initWithAssetsLibrary:(ALAssetsLibrary *)assetsLibrary delegate:(id<ImageManagerDelegate>)delegateToAdd;

-(void)addImages:(NSArray *)imagesToAdd toAlbum:(NSString *)album;
-(UIImage *)generateRandomImage;

@end
