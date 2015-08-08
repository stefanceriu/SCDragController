//
//  AppDelegate.m
//  SCDragController
//
//  Created by Stefan Ceriu on 8/8/15.
//  Copyright (c) 2015 Stefan Ceriu. All rights reserved.
//

#import "AppDelegate.h"
#import "SCRootViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.rootViewController = [[SCRootViewController alloc] initWithNibName:NSStringFromClass([SCRootViewController class]) bundle:nil];
	[self.window makeKeyAndVisible];
	
	return YES;
}

@end
