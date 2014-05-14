//
//  FeatureAPI.m
//  AddContacts
//
//  Created by Jason Bandy on 5/7/14.
//  Copyright (c) 2014 Jason Bandy. All rights reserved.
//

#import "FeatureAPI.h"

#import "AddContactsModel.h"
#import "AddPhotosModel.h"
#import "AddVideosModel.h"

@implementation FeatureAPI


// public facing initializer TODO: May make this apart of the static accessor if not inited just init then.
-(BOOL)initializeFeatureAPI{
    return NO;
}

// singleton accessor
+(FeatureAPI*)singleFeatureAPI {
    return [[FeatureAPI alloc]init];
}

// Add Contact Feature Set
-(BOOL)requestAccessToABBook {
    return NO;
}
-(void)addContacts:(NSArray*)contactsToAdd withCompletionBlock:(APICompletionBlock)completionBlock {
    
}
-(void)removeAllContactsWithCompletionBlock:(APICompletionBlock)completionBlock{
    
}

// Add Photos Feature Set
-(void)addPhotos:(NSArray*) imagesToAdd toAlbumName:(NSString*)albumName withCompletionBlock:(APICompletionBlock)completionBlock{
    
}
// This API call will use the random image generator
-(void)addRandomPhotosWithCount:(NSUInteger*)imageCount toAlbumName:(NSString*)albumName withCompletionBlock:(APICompletionBlock)completionBlock{
    
}

@end
