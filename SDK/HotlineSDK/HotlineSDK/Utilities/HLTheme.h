//
//  HLTheme.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 30/09/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HLTheme : NSObject

+ (instancetype)sharedInstance;
+(UIImage *)getImageFromMHBundleWithName:(NSString *)imageName;

-(UIColor *)gridViewItemBackgroundColor;

//Dialogues
-(UIColor *)getButtontextColorForKey:(NSString *)key;
-(UIFont *)dialogueTitleFont;
-(UIColor *)dialogueTitleTextColor;
-(UIFont *)dialogueButtonFont;
-(UIColor *)dialogueButtonTextColor;
-(UIColor *)dialogueBackgroundColor;

@end
