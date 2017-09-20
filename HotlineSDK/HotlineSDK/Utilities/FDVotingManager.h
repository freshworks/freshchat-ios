//
//  FDVotingManager.h
//  FreshdeskSDK
//
//  Created by kirthikas on 12/08/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDVotingManager : NSObject

+(instancetype)sharedInstance;
-(void)downVoteForArticle:(NSNumber *)articleID inCategory:(NSNumber *)categoryID withCompletion:(void(^)(NSError *error))completion;
-(void)upVoteForArticle:(NSNumber *)articleID inCategory:(NSNumber *)categoryID withCompletion:(void(^)(NSError *error))completion;
-(BOOL)isArticleVoted:(NSNumber *)articleID;
-(BOOL)getArticleVoteFor:(NSNumber *)articleID;

@end
