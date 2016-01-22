//
//  FDVotingManager.m
//  FreshdeskSDK
//
//  Created by kirthikas on 12/08/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDVotingManager.h"
#import "FDSecureStore.h"
#import "HLFAQServices.h"

#define MOBIHELP_DEFAULTS_VOTED_ARTICLES @"mobihelp_defaults_voted_articles"


@interface FDVotingManager()

@property (strong,nonatomic) NSMutableDictionary *votedArticlesDictionary;

@end

@implementation FDVotingManager

+(instancetype)sharedInstance{
    static FDVotingManager *sharedInstance = nil;
    static dispatch_once_t oncetoken;
    dispatch_once(&oncetoken,^{
        sharedInstance = [[FDVotingManager alloc]init];
    });
    return sharedInstance;
}

-(instancetype)init{
    self = [super init];
    if (self) {
        FDSecureStore *secureStore = [FDSecureStore sharedInstance];
        if([secureStore checkItemWithKey:MOBIHELP_DEFAULTS_VOTED_ARTICLES]){
            self.votedArticlesDictionary = [secureStore objectForKey:MOBIHELP_DEFAULTS_VOTED_ARTICLES];
        }
        else{
            self.votedArticlesDictionary = [[NSMutableDictionary alloc]init];
        }
    }
    return self;
}

-(void)downVoteForArticle:(NSNumber *)articleID inCategory:(NSNumber *)categoryID withCompletion:(void(^)(NSError *error))completion{
    NSLog(@"Article Downvoted");
    [self storeArticleVote:NO LocallyForArticleID:articleID];
    HLFAQServices *service = [[HLFAQServices alloc]init];
    [service vote:NO forArticleID:articleID inCategoryID:categoryID];
}

-(void)upVoteForArticle:(NSNumber *)articleID inCategory:(NSNumber *)categoryID withCompletion:(void(^)(NSError *error))completion{
    NSLog(@"Article Upvoted");
    [self storeArticleVote:YES LocallyForArticleID:articleID];
    HLFAQServices *service = [[HLFAQServices alloc]init];
    [service vote:YES forArticleID:articleID inCategoryID:categoryID];
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

-(BOOL)getArticleVoteFor:(NSNumber *)articleID{
    NSString * articleIDString = [NSString stringWithFormat:@"%@",articleID];
    BOOL isArticleVoted = [[self.votedArticlesDictionary valueForKey:articleIDString] boolValue];
    return isArticleVoted;
}

-(void)storeArticleVote:(BOOL)vote LocallyForArticleID:(NSNumber *)articleID{
    FDSecureStore *secureStore = [FDSecureStore sharedInstance];
    NSString * articleIDString = [NSString stringWithFormat:@"%@",articleID];
    [self.votedArticlesDictionary setValue:@(vote) forKey:articleIDString];
    [secureStore setObject:self.votedArticlesDictionary forKey:MOBIHELP_DEFAULTS_VOTED_ARTICLES];
}

@end
