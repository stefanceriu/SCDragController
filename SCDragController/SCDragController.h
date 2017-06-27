//
//  SCDragController.h
//  SCDragController
//
//  Created by Stefan Ceriu on 8/8/15.
//  Copyright (c) 2015 Stefan Ceriu. All rights reserved.
//

@import UIKit;

@protocol SCDragControllerDataSource;
@protocol SCDragControllerDelegate;

@interface SCDragController : NSObject

@property (nonatomic, weak) id<SCDragControllerDataSource> dataSource;
@property (nonatomic, weak) id<SCDragControllerDelegate> delegate;

@property (nonatomic, strong, readonly) UIView *view;
@property (nonatomic, strong, readonly) UILongPressGestureRecognizer *longPressGesture;

@property (nonatomic, strong, readonly) UIView *draggedView;
@property (nonatomic, strong, readonly) id currentDragMetadata;

@property (nonatomic, weak, readonly) UIView *currentDragSource;
@property (nonatomic, weak, readonly) UIView *currentDragDestination;

@property (nonatomic, readonly) NSSet *sources;
@property (nonatomic, readonly) NSSet *destinations;

- (instancetype)initWithView:(UIView *)view;

- (void)registerSource:(UIView *)source;
- (void)deregisterSource:(UIView *)source;
- (void)deregisterAllSources;

- (void)registerDestination:(UIView *)destination;
- (void)deregisterDestination:(UIView *)destination;
- (void)deregisterAllDestinations;

@end


@protocol SCDragControllerDataSource <NSObject>

@optional

- (UIView *)dragController:(SCDragController *)dragController dragViewForPosition:(CGPoint)position source:(UIView *)source;

- (id)dragController:(SCDragController *)dragController dragMetadataForPosition:(CGPoint)position source:(UIView *)source;

- (BOOL)dragController:(SCDragController *)dragController shouldStartDragForPosition:(CGPoint)position source:(UIView *)source;

@end


@protocol SCDragControllerDelegate <NSObject>

@optional

- (void)dragController:(SCDragController *)dragController willStartDragAtPosition:(CGPoint)position;

- (void)dragController:(SCDragController *)dragController animateDragStartForView:(UIView *)dragView
			  position:(CGPoint)position
			completion:(void(^)())completion;

- (void)dragController:(SCDragController *)dragController didStartDragAtPosition:(CGPoint)position;



- (void)dragController:(SCDragController *)dragController willUpdateDragPosition:(inout CGPoint *)position;

- (void)dragController:(SCDragController *)dragController didUpdateDragPosition:(CGPoint)position;



- (void)dragController:(SCDragController *)dragController dragDidEnterDestination:(UIView *)destination position:(CGPoint)position;

- (void)dragController:(SCDragController *)dragController dragDidLeaveDestination:(UIView *)destination position:(CGPoint)position;


- (BOOL)dragController:(SCDragController *)dragController shouldFinishDragAtPosition:(CGPoint)position
                source:(UIView *)source
           destination:(UIView *)destination
              metadata:(id)metadata;

- (void)dragController:(SCDragController *)dragController willFinishDragAtPosition:(CGPoint)position;

- (void)dragController:(SCDragController *)dragController animateDragFinishForView:(UIView *)dragView
			  position:(CGPoint)position
			completion:(void(^)())completion;

- (void)dragController:(SCDragController *)dragController didFinishDragAtPosition:(CGPoint)position
				source:(UIView *)source
		   destination:(UIView *)destination
			  metadata:(id)metadata;




- (void)dragController:(SCDragController *)dragController willCancelDragAtPosition:(CGPoint)position dragStartPosition:(CGPoint)dragStartPosition;

- (void)dragController:(SCDragController *)dragController animateDragCancelForView:(UIView *)dragView
			  position:(CGPoint)position
	 dragStartPosition:(CGPoint)dragStartPosition
			completion:(void(^)())completion;

- (void)dragController:(SCDragController *)dragController didCancelDragAtPosition:(CGPoint)position dragStartPosition:(CGPoint)dragStartPosition;

@end
