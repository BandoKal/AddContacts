//
//  FeatureAPI.m
//  AddContacts
//
//  Created by Jason Bandy on 5/7/14.
//  Copyright (c) 2014 Jason Bandy. All rights reserved.
//

#import "FeatureAPI.h"

#import "AddContactsModel.h"
#import "AddVideosModel.h"
#import "ALAssetsLibrary+LibraryHelper.h"

@interface FeatureAPI ()

@property (nonatomic, strong) ImageManager *imageManager;
@property (copy) APICompletionBlock imageOperationCompletionBlock;

@end

@implementation FeatureAPI

#pragma mark - Public Methods
// singleton accessor
+(FeatureAPI*)singleFeatureAPI {
    static FeatureAPI *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance =[[FeatureAPI alloc]init];
    });
    return sharedInstance;
}

+(ALAssetsLibrary*)singleAlAssetsLibrary {
    static ALAssetsLibrary *sharedLibrary = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedLibrary = [[ALAssetsLibrary alloc]init];
    });
    return sharedLibrary;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        _imageManager = [[ImageManager alloc] initWithAssetsLibrary:[FeatureAPI singleAlAssetsLibrary] delegate:self];
    }
    return self;
}

#pragma mark Contacts Feature Set
-(BOOL)requestAccessToABBook {
    return NO;
}

-(void)addContacts:(NSArray*)contactsToAdd withCompletionBlock:(APICompletionBlock)completionBlock {
    
}

-(void)removeAllContactsWithCompletionBlock:(APICompletionBlock)completionBlock{
    
}

#pragma mark Photo Feature Set
-(void)addPhotos:(NSArray*)imagesToAdd toAlbumName:(NSString*)albumName withCompletionBlock:(APICompletionBlock)completionBlock {
    self.imageOperationCompletionBlock = completionBlock;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.imageManager addImages:imagesToAdd toAlbum:albumName];
    });
}

-(void)addRandomPhotosWithCount:(NSUInteger)imageCount toAlbumName:(NSString*)albumName withCompletionBlock:(APICompletionBlock)completionBlock {
    self.imageOperationCompletionBlock = completionBlock;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.imageManager addRandomImagesWithCount:imageCount toAlbum:albumName];
    });
}

#pragma mark Image Manager Delegate Handlers
-(void)currentProgress:(NSUInteger)currentProgress ofTotal:(NSUInteger)total {
    float percentageComplete = ((float)currentProgress)/total;
    NSLog(@"Image operation progress update: %f", percentageComplete);
    [self.delegate statusUpdateFromModelWithInfoObject:[NSNumber numberWithFloat:percentageComplete] error:nil];
}

-(void)imageOperationCompletedSuccessfully {
    NSLog(@"Image operation completed successfully");
    self.imageOperationCompletionBlock(nil);
}

-(void)imageOperationFailedCompletelyWithError:(NSError *)error {
    NSLog(@"Image operation failed completely with error: %@", error);
    self.imageOperationCompletionBlock(error);
}

-(void)imageOperationFailedPartiallyWithError:(NSError *)error onObject:(id)failedObject {
    NSLog(@"Image operation failed with error: %@", error);
    [self.delegate statusUpdateFromModelWithInfoObject:failedObject error:error];
}

@end
