//
//  FDVotingManager.m
//  FreshdeskSDK
//
//  Created by kirthikas on 12/08/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FCVotingManager.h"
#import "FCSecureStore.h"
#import "FCMacros.h"
#import "FCFAQServices.h"
#import "FCRemoteConfig.h"

@interface FCVotingManager()


@end

@implementation FCVotingManager

+(instancetype)sharedInstance{
    static FCVotingManager *sharedInstance = nil;
    static dispatch_once_t oncetoken;
    dispatch_once(&oncetoken,^{
        sharedInstance = [[FCVotingManager alloc]init];
    });
    return sharedInstance;
}

-(instancetype)init{
    self = [super init];
    if (self) {
        FCSecureStore *secureStore = [FCSecureStore sharedInstance];
        if([secureStore checkItemWithKey:HOTLINE_DEFAULTS_VOTED_ARTICLES]){
            self.votedArticlesDictionary = [secureStore objectForKey:HOTLINE_DEFAULTS_VOTED_ARTICLES];
        }
        else{
            self.votedArticlesDictionary = [[NSMutableDictionary alloc]init];
        }
    }
    return self;
}

-(void)downVoteForArticle:(NSNumber *)articleID inCategory:(NSNumber *)categoryID withCompletion:(void(^)(NSError *error))completion{
    if([[FCRemoteConfig sharedInstance] isActiveFAQAndAccount]){
        ALog(@"Article Downvoted");
        [self storeArticleVote:NO LocallyForArticleID:articleID];
        FCFAQServices *service = [[FCFAQServices alloc]init];
        [service vote:NO forArticleID:articleID inCategoryID:categoryID];
        if(completion){
            completion(nil);
        }
    }
}

-(void)upVoteForArticle:(NSNumber *)articleID inCategory:(NSNumber *)categoryID withCompletion:(void(^)(NSError *error))completion{
    if([[FCRemoteConfig sharedInstance] isActiveFAQAndAccount]){
        ALog(@"Article Upvoted");
        [self storeArticleVote:YES LocallyForArticleID:articleID];
        FCFAQServices *service = [[FCFAQServices alloc]init];
        [service vote:YES forArticleID:articleID inCategoryID:categoryID];
        if(completion){
            completion(nil);
        }
    }
}

-(BOOL)isArticleDownvoted:(NSNumber *)articleID {
    NSString * articleIDString = [NSString stringWithFormat:@"%@",articleID];
    return (![[self.votedArticlesDictionary objectForKey:articleIDString] boolValue]);
}

-(BOOL)isArticleVoted:(NSNumber *)articleID{
    NSString * articleIDString = [NSString stringWithFormat:@"%@",articleID];
    if ([self.votedArticlesDictionary valueForKey:articleIDString]) {
        return YES;
    }
    else{
        return NO;
    }
}

-(void) clearVotingForArticle : (NSNumber *) articleID {
    NSString *articleIDString = [NSString stringWithFormat:@"%@",articleID];
    [self.votedArticlesDictionary removeObjectForKey:articleIDString];
}

-(BOOL)getArticleVoteFor:(NSNumber *)articleID{
    NSString * articleIDString = [NSString stringWithFormat:@"%@",articleID];
    BOOL isArticleVoted = [[self.votedArticlesDictionary valueForKey:articleIDString] boolValue];
    return isArticleVoted;
}

-(void)storeArticleVote:(BOOL)vote LocallyForArticleID:(NSNumber *)articleID{
    FCSecureStore *secureStore = [FCSecureStore sharedInstance];
    NSString * articleIDString = [NSString stringWithFormat:@"%@",articleID];
    [self.votedArticlesDictionary setValue:@(vote) forKey:articleIDString];
    [secureStore setObject:self.votedArticlesDictionary forKey:HOTLINE_DEFAULTS_VOTED_ARTICLES];
}

@end
