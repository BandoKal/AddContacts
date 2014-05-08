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

-(BOOL)initializeFeatureAPI {
    return YES;
}

+(FeatureAPI*)singleFeatureAPI {
    return nil;
}

-(BOOL)requestAccessToABBook {
    return YES;
}

-(void)addContacts:(NSArray*)contactsToAdd withCompletionBlock:(APICompletionBlock)completionBlock {
}

-(void)removeAllContactsWithCompletionBlock:(APICompletionBlock)completionBlock {
}

-(void)addPhotos:(NSArray*)imagesToAdd toAlbumName:(NSString*)albumName withCompletionBlock:(APICompletionBlock)completionBlock {
}

-(void)addRandomPhotosWithCount:(NSUInteger*)imageCount toAlbumName:(NSString*)albumName withCompletionBlock:(APICompletionBlock)completionBlock {
}

@end
