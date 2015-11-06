//
//  SCDragController.m
//  SCDragController
//
//  Created by Stefan Ceriu on 8/8/15.
//  Copyright (c) 2015 Stefan Ceriu. All rights reserved.
//

#import "SCDragController.h"

@interface SCDragController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *view;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGesture;

@property (nonatomic, strong) NSMutableSet *dragSources;
@property (nonatomic, strong) NSMutableSet *dragDestinations;

@property (nonatomic, strong) UIView *draggedView;
@property (nonatomic, strong) id currentDragMetadata;
@property (nonatomic, weak) UIView *currentDragSource;
@property (nonatomic, weak) UIView *currentDragDestination;

@property (nonatomic, assign) CGPoint currentDragStartPosition;

@end

@implementation SCDragController

- (void)dealloc
{
    [self.view removeGestureRecognizer:self.longPressGesture];
}

- (instancetype)initWithView:(UIView *)view
{
	if(self = [super init]) {
		_view = view;
		
		_longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_onLongPress:)];
		[_longPressGesture setDelegate:self];
		[_longPressGesture setMinimumPressDuration:0.1f];
		[_view addGestureRecognizer:_longPressGesture];
		
		_dragSources = [NSMutableSet set];
		_dragDestinations = [NSMutableSet set];
	}
	
	return self;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	CGPoint position = [touch locationInView:self.view];
	
	UIView *source = [self _sourceAtPosition:position];
	
	if(source == nil) {
		return NO;
	}
	
	BOOL shouldStartDrag = YES;
	if([self.dataSource respondsToSelector:@selector(dragController:shouldStartDragForPosition:source:)]) {
		shouldStartDrag = [self.dataSource dragController:self shouldStartDragForPosition:position source:source];
	}
	
	if(shouldStartDrag) {
		self.currentDragSource = source;
	}
	
	return shouldStartDrag;
}

#pragma mark - Private

- (void)_onLongPress:(UIGestureRecognizer *)gestureRecognizer
{
	CGPoint position = [gestureRecognizer locationInView:self.view];
	
	switch (gestureRecognizer.state) {
		case UIGestureRecognizerStateBegan: {
			[self _startDragAtPosition:position];
			break;
		}
		case UIGestureRecognizerStateChanged: {
			[self _updateDragWithPosition:position];
			break;
		}
		case UIGestureRecognizerStateEnded:
		case UIGestureRecognizerStateCancelled: {
			[self _endDragAtPosition:position];
			break;
		}
		default: {
			break;
		}
	}
}

- (void)_startDragAtPosition:(CGPoint)position
{
	self.currentDragStartPosition = position;
	
	if([self.dataSource respondsToSelector:@selector(dragController:dragViewForPosition:source:)]) {
		self.draggedView = [self.dataSource dragController:self dragViewForPosition:position source:self.currentDragSource];
	} else {
		self.draggedView = [self.currentDragSource snapshotViewAfterScreenUpdates:NO];
	}
	
	[self.view addSubview:self.draggedView];
	
	if([self.dataSource respondsToSelector:@selector(dragController:dragMetadataForPosition:source:)]) {
		self.currentDragMetadata = [self.dataSource dragController:self dragMetadataForPosition:position source:self.currentDragSource];
	}
	
	if([self.delegate respondsToSelector:@selector(dragController:willStartDragAtPosition:)]) {
		[self.delegate dragController:self willStartDragAtPosition:position];
	}
	
	dispatch_group_t dispatchGroup = dispatch_group_create();
	if([self.delegate respondsToSelector:@selector(dragController:animateDragStartForView:position:completion:)]) {
		dispatch_group_enter(dispatchGroup);
		[self.delegate dragController:self
			  animateDragStartForView:self.draggedView
							 position:position
						   completion:^{
							   dispatch_group_leave(dispatchGroup);
						   }];
	}
	
	dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
		if([self.delegate respondsToSelector:@selector(dragController:didStartDragAtPosition:)]) {
			[self.delegate dragController:self didStartDragAtPosition:position];
		}
		
		[self _updateDragWithPosition:position];
	});
}

- (void)_updateDragWithPosition:(CGPoint)position
{
	if([self.delegate respondsToSelector:@selector(dragController:willUpdateDragPosition:)]) {
		[self.delegate dragController:self willUpdateDragPosition:&position];
	}
	
	[self.draggedView setCenter:position];
	
	if([self.delegate respondsToSelector:@selector(dragController:didUpdateDragPosition:)]) {
		[self.delegate dragController:self didUpdateDragPosition:position];
	}
	
	UIView *destination = [self _destinationAtPosition:position];
	
	if(destination == self.currentDragDestination || [destination isEqual:self.currentDragDestination]) {
		return;
	}
	
	if(self.currentDragDestination && destination) {
		
		if([self.delegate respondsToSelector:@selector(dragController:dragDidLeaveDestination:position:)]) {
			[self.delegate dragController:self dragDidLeaveDestination:self.currentDragDestination position:position];
		}
		
		self.currentDragDestination = destination;
		
		if([self.delegate respondsToSelector:@selector(dragController:dragDidEnterDestination:position:)]) {
			[self.delegate dragController:self dragDidEnterDestination:self.currentDragDestination position:position];
		}
		
	} else if(self.currentDragDestination) {
		
		if([self.delegate respondsToSelector:@selector(dragController:dragDidLeaveDestination:position:)]) {
			[self.delegate dragController:self dragDidLeaveDestination:self.currentDragDestination position:position];
		}
		
		self.currentDragDestination = nil;
		
	} else if(destination) {
		
		self.currentDragDestination = destination;
		
		if([self.delegate respondsToSelector:@selector(dragController:dragDidEnterDestination:position:)]) {
			[self.delegate dragController:self dragDidEnterDestination:self.currentDragDestination position:position];
		}
	}
}

- (void)_endDragAtPosition:(CGPoint)position
{
	if(self.currentDragDestination) {
		if([self.delegate respondsToSelector:@selector(dragController:willFinishDragAtPosition:)]) {
			[self.delegate dragController:self willFinishDragAtPosition:position];
		}
		
		dispatch_group_t dispatchGroup = dispatch_group_create();
		if([self.delegate respondsToSelector:@selector(dragController:animateDragFinishForView:position:completion:)]) {
			dispatch_group_enter(dispatchGroup);
			[self.delegate dragController:self
				 animateDragFinishForView:self.draggedView
								 position:position
							   completion:^{
								   dispatch_group_leave(dispatchGroup);
							   }];
		}
		
		dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
			
			if([self.delegate respondsToSelector:@selector(dragController:didFinishDragAtPosition:source:destination:metadata:)]) {
				[self.delegate dragController:self didFinishDragAtPosition:position source:self.currentDragSource destination:self.currentDragDestination metadata:self.currentDragMetadata];
			}
			
			[self.draggedView removeFromSuperview];
			self.draggedView = nil;
			self.currentDragMetadata = nil;
			self.currentDragSource = nil;
			self.currentDragDestination = nil;
		});
		
	} else {
	
		if([self.delegate respondsToSelector:@selector(dragController:willCancelDragAtPosition:dragStartPosition:)]) {
			[self.delegate dragController:self willCancelDragAtPosition:position dragStartPosition:self.currentDragStartPosition];
		}
		
		dispatch_group_t dispatchGroup = dispatch_group_create();
		
		if([self.delegate respondsToSelector:@selector(dragController:animateDragCancelForView:position:dragStartPosition:completion:)]) {
			dispatch_group_enter(dispatchGroup);
			[self.delegate dragController:self
				 animateDragCancelForView:self.draggedView
								 position:position
						dragStartPosition:self.currentDragStartPosition
							   completion:^{
								   dispatch_group_leave(dispatchGroup);
							   }];
		}
		
		dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
            
            if([self.delegate respondsToSelector:@selector(dragController:didCancelDragAtPosition:dragStartPosition:)]) {
                [self.delegate dragController:self didCancelDragAtPosition:position dragStartPosition:self.currentDragStartPosition];
            }
			
			[self.draggedView removeFromSuperview];
			self.draggedView = nil;
			self.currentDragMetadata = nil;
			self.currentDragSource = nil;
			self.currentDragDestination = nil;
			
		});
	}
}

- (UIView *)_sourceAtPosition:(CGPoint)position
{
	for(UIView *source in self.dragSources) {
		CGRect frame = [self.view convertRect:source.frame fromView:source.superview];
		if(CGRectContainsPoint(frame, position)) {
			return source;
		}
	}
	
	return nil;
}

- (UIView *)_destinationAtPosition:(CGPoint)position
{
	for(UIView *destination in self.dragSources) {
		CGRect frame = [self.view convertRect:destination.frame fromView:destination.superview];
		if(CGRectContainsPoint(frame, position)) {
			return destination;
		}
	}
	
	return nil;
}

#pragma mark - Registration

- (void)registerSource:(UIView *)source
{
	NSParameterAssert(source);
	
	[self.dragSources addObject:source];
}

- (void)deregisterSource:(UIView *)source
{
	NSParameterAssert(source);
	
	[self.dragSources removeObject:source];
}

- (void)deregisterAllSources
{
	[self.dragSources removeAllObjects];
}

- (void)registerDestination:(UIView *)destination
{
	NSParameterAssert(destination);
	
	[self.dragDestinations addObject:destination];
}

- (void)deregisterDestination:(UIView *)destination
{
	NSParameterAssert(destination);
	
	[self.dragDestinations removeObject:destination];
}

- (void)deregisterAllDestinations
{
	[self.dragDestinations removeAllObjects];
}

- (NSSet *)sources
{
	return self.dragSources.copy;
}

- (NSSet *)destinations
{
	return self.dragDestinations.copy;
}

@end
