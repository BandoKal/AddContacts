//
//  FeatureAPI.h
//  AddContacts
//
//  Created by Jason Bandy on 5/7/14.
//  Copyright (c) 2014 Jason Bandy. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void(^APICompletionBlock)(NSError *error);


@protocol FeatureAPIDelegate <NSObject>

@required
// use this method to update the controllers of any update.
-(void)statusUpdateFromModelWithInfoObject:(float)percentComplete error:(NSError*)error;

@end

@interface FeatureAPI : NSObject

// public facing initializer TODO: May make this apart of the static accessor if not inited just init then.
-(BOOL)initializeFeatureAPI;

// singleton accessor
+(FeatureAPI*)singleFeatureAPI;

// Add Contact Feature Set
-(BOOL)requestAccessToABBook;
-(void)addContacts:(NSArray*)contactsToAdd withCompletionBlock:(APICompletionBlock)completionBlock;
-(void)removeAllContactsWithCompletionBlock:(APICompletionBlock)completionBlock;;

// Add Photos Feature Set
-(void)addPhotos:(NSArray*)imagesToAdd toAlbumName:(NSString*)albumName withCompletionBlock:(APICompletionBlock)completionBlock;
// This API call will use the random image generator
-(void)addRandomPhotosWithCount:(NSUInteger*)imageCount toAlbumName:(NSString*)albumName withCompletionBlock:(APICompletionBlock)completionBlock;

@end
