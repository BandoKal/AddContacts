//
//  VideoManager.h
//  AddContacts
//
//  Created by Jason Bandy on 5/7/14.
//  Copyright (c) 2014 Jason Bandy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>

@class ALAssetsLibrary, ImageManager;

#pragma mark Error Variables
NSString *const BCGvideoManipulationErrorDomain;

typedef NS_ENUM(NSInteger, BCGVideoManipulationErrorCode) {
    BCGVideoManipulationErrorCode_FailedStartingVideoWritingSession,
    BCGVideoManipulationErrorCode_FailedAppendingPixelBuffer,
//    BCGVideoManipulationErrorCode_TimeoutDuringVideoImport,
};

#pragma mark Video Manager Delegate
@protocol VideoManagerDelegate <NSObject>

@optional
-(void)currentVideoProgress:(NSUInteger)currentProgress ofTotal:(NSUInteger)total;
-(void)videoOperationCompletedSuccessfully;
-(void)videoOperationFailedCompletelyWithError:(NSError *)error;

@end

@interface VideoManager : NSObject

-(instancetype)init __attribute__((unavailable("use initWithAssetsLibrary:delegate: instead")));
-(instancetype)initWithAssetsLibrary:(ALAssetsLibrary *)assetsLibrary delegate:(id<VideoManagerDelegate>)delegateToAdd;

//-(void)addRandomVideoForFileSize:(NSUInteger)fileSize images:(NSArray*)imagesArray;
//-(void)addRandomVideoForDuration:(int)duration images:(NSArray*)imagesArray;
-(void)addRandomVideoForDuration:(int)duration imageManager:(ImageManager *)imageManager;

-(void)cleanupTempVideos;
-(NSString *)tempVideoPath;

@end
