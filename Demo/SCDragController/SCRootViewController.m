//
//  ViewController.m
//  SCDragController
//
//  Created by Stefan Ceriu on 8/8/15.
//  Copyright (c) 2015 Stefan Ceriu. All rights reserved.
//

#import "SCRootViewController.h"

#import "SCDragController.h"

#import "SCCollectionViewCell.h"

@interface SCRootViewController () <UICollectionViewDataSource, SCDragControllerDataSource, SCDragControllerDelegate>

@property (nonatomic, strong) SCDragController *dragController;

@property (nonatomic, weak) IBOutlet UICollectionView *firstCollectionView;
@property (nonatomic, weak) IBOutlet UICollectionView *secondCollectionView;

@property (nonatomic, strong) NSMutableArray *firstDataSource;
@property (nonatomic, strong) NSMutableArray *secondDataSource;

@end

@implementation SCRootViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.dragController = [[SCDragController alloc] initWithView:self.view];
	[self.dragController setDataSource:self];
	[self.dragController setDelegate:self];

	NSString *identifier = NSStringFromClass([SCCollectionViewCell class]);
	[self.firstCollectionView registerNib:[UINib nibWithNibName:identifier bundle:nil] forCellWithReuseIdentifier:identifier];
	[self.secondCollectionView registerNib:[UINib nibWithNibName:identifier bundle:nil] forCellWithReuseIdentifier:identifier];
	
	self.firstDataSource = [NSMutableArray array];
	self.secondDataSource = [NSMutableArray array];
	
	for(int i = 0; i < 10; i++) {
		[self.firstDataSource addObject:[NSString stringWithFormat:@"%d", i]];
	}
	
	for(int i = 10; i < 20; i++) {
		[self.secondDataSource addObject:[NSString stringWithFormat:@"%d", i]];
	}
	
	[self.dragController registerSource:self.firstCollectionView];
	[self.dragController registerSource:self.secondCollectionView];
	
	[self.dragController registerDestination:self.firstCollectionView];
	[self.dragController registerDestination:self.secondCollectionView];
}

#pragma mark - SCDragControllerDataSource

- (BOOL)dragController:(SCDragController *)dragController shouldStartDragForPosition:(CGPoint)position source:(UICollectionView *)source
{
	CGPoint adjustedPosition = [source convertPoint:position fromView:dragController.view];
	UICollectionViewCell *cell = [source cellForItemAtIndexPath:[source indexPathForItemAtPoint:adjustedPosition]];
	
	return (cell != nil);
}

- (UIView *)dragController:(SCDragController *)dragController dragViewForPosition:(CGPoint)position source:(UICollectionView *)source
{
	CGPoint adjustedPosition = [dragController.view convertPoint:position toView:source];
	UICollectionViewCell *cell = [source cellForItemAtIndexPath:[source indexPathForItemAtPoint:adjustedPosition]];
	
	UIView *cellPlaceholder = [cell snapshotViewAfterScreenUpdates:NO];
	[cellPlaceholder setAlpha:0.0f];
	[cellPlaceholder setFrame:[dragController.view convertRect:cell.frame fromView:cell.superview]];
	
	return cellPlaceholder;
}

- (id)dragController:(SCDragController *)dragController dragMetadataForPosition:(CGPoint)position source:(UICollectionView *)source
{
	CGPoint adjustedPosition = [dragController.view convertPoint:position toView:source];
	NSIndexPath *indexPath = [source indexPathForItemAtPoint:adjustedPosition];
	
	if(indexPath == nil) {
		return nil;
	}
	
	if([source isEqual:self.firstCollectionView]) {
		return [self.firstDataSource objectAtIndex:indexPath.row];
	} else {
		return [self.secondDataSource objectAtIndex:indexPath.row];
	}
}

#pragma mark - SCDragControllerDelegate

- (void)dragController:(SCDragController *)dragController dragDidEnterDestination:(UICollectionView *)destination position:(CGPoint)position
{
	CGPoint adjustedPosition = [dragController.view convertPoint:position toView:destination];
	[self _insertObject:dragController.currentDragMetadata intoDestination:destination atPosition:adjustedPosition];
}

- (void)dragController:(SCDragController *)dragController dragDidLeaveDestination:(UICollectionView *)destination position:(CGPoint)position
{
	if([destination isEqual:self.firstCollectionView]) {
		NSUInteger index = [self.firstDataSource indexOfObject:dragController.currentDragMetadata];
		[self.firstDataSource removeObjectAtIndex:index];
		[self.firstCollectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
	} else {
		NSUInteger index = [self.secondDataSource indexOfObject:dragController.currentDragMetadata];
		[self.secondDataSource removeObjectAtIndex:index];
		[self.secondCollectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
	}
}

- (void)dragController:(SCDragController *)dragController animateDragStartForView:(UIView *)dragView position:(CGPoint)position completion:(void (^)())completion
{
	[UIView animateWithDuration:0.25f animations:^{
		[dragView setAlpha:0.8f];
		[dragView setCenter:position];
	} completion:^(BOOL finished) {
		completion();
	}];
}

- (void)dragController:(SCDragController *)dragController didUpdateDragPosition:(CGPoint)position
{
	UICollectionView *destination = (UICollectionView *)dragController.currentDragDestination;
	
	if(!destination) {
		return;
	}
	
	CGPoint adjustedPosition = [dragController.view convertPoint:position toView:destination];
	NSIndexPath *indexPath = [self _closestCellIndexPathToPoint:adjustedPosition inCollectionView:destination];
	
	if([destination isEqual:self.firstCollectionView]) {
		NSUInteger index = [self.firstDataSource indexOfObject:dragController.currentDragMetadata];
		
		if(indexPath.row == index) {
			return;
		}
		
		id object = [self.firstDataSource objectAtIndex:index];
		[self.firstDataSource removeObjectAtIndex:index];
		[self.firstDataSource insertObject:object atIndex:indexPath.row];
		
		[self.firstCollectionView moveItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] toIndexPath:indexPath];
		
	} else {
		
		NSUInteger index = [self.secondDataSource indexOfObject:dragController.currentDragMetadata];
		
		if(indexPath.row == index) {
			return;
		}
		
		id object = [self.secondDataSource objectAtIndex:index];
		[self.secondDataSource removeObjectAtIndex:index];
		[self.secondDataSource insertObject:object atIndex:indexPath.row];
		
		[self.secondCollectionView moveItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] toIndexPath:indexPath];
	}
}

- (void)dragController:(SCDragController *)dragController didCancelDragAtPosition:(CGPoint)position dragStartPosition:(CGPoint)dragStartPosition
{
	CGPoint adjustedPosition = [dragController.view convertPoint:dragStartPosition toView:dragController.currentDragSource];
	[self _insertObject:dragController.currentDragMetadata intoDestination:dragController.currentDragSource atPosition:adjustedPosition];
}

- (void)dragController:(SCDragController *)dragController animateDragFinishForView:(UIView *)dragView
			  position:(CGPoint)position
			completion:(void (^)())completion
{
	UICollectionView *destination = (UICollectionView *)dragController.currentDragDestination;
	
	CGPoint adjustedPosition = [dragController.view convertPoint:position toView:destination];
	NSIndexPath *indexPath = [self _closestCellIndexPathToPoint:adjustedPosition inCollectionView:(UICollectionView *)destination];
	
	UICollectionViewCell *cell = [destination cellForItemAtIndexPath:indexPath];
	
	[UIView animateWithDuration:0.25f animations:^{
		[dragView setFrame:[dragController.view convertRect:cell.frame fromView:destination]];
	} completion:^(BOOL finished) {
		[UIView animateWithDuration:0.25f animations:^{
			[dragView setAlpha:0.0f];
		} completion:^(BOOL finished) {
			completion();
		}];
	}];
}

- (void)dragController:(SCDragController *)dragController animateDragCancelForView:(UIView *)dragView
			  position:(CGPoint)position
	 dragStartPosition:(CGPoint)dragStartPosition
			completion:(void (^)())completion
{
	UICollectionView *source = (UICollectionView *)dragController.currentDragSource;
	
	CGPoint adjustedPosition = [dragController.view convertPoint:dragStartPosition toView:source];
	UICollectionViewCell *cell = [source cellForItemAtIndexPath:[source indexPathForItemAtPoint:adjustedPosition]];
	
	[UIView animateWithDuration:0.25f animations:^{
		[dragView setFrame:[dragController.view convertRect:cell.frame fromView:source]];
	} completion:^(BOOL finished) {
		[UIView animateWithDuration:0.25f animations:^{
			[dragView setAlpha:0.0f];
		} completion:^(BOOL finished) {
			completion();
		}];
	}];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	if([collectionView isEqual:self.firstCollectionView]) {
		return self.firstDataSource.count;
	} else {
		return self.secondDataSource.count;
	}
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *identifier = NSStringFromClass([SCCollectionViewCell class]);
	SCCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
	
	if([collectionView isEqual:self.firstCollectionView]) {
		[cell.titleLabel setText:self.firstDataSource[indexPath.row]];
	} else {
		[cell.titleLabel setText:self.secondDataSource[indexPath.row]];
	}
	
	return cell;
}

#pragma mark - Private

- (void)_insertObject:(id)object intoDestination:(UIView *)destination atPosition:(CGPoint)position
{
	NSIndexPath *indexPath = [self _closestCellIndexPathToPoint:position inCollectionView:(UICollectionView *)destination];
	
	if([destination isEqual:self.firstCollectionView]) {
		
		if([self.firstDataSource containsObject:object]) {
			return;
		}
		
		[self.firstDataSource insertObject:object atIndex:indexPath.row];
		[self.firstCollectionView insertItemsAtIndexPaths:@[indexPath]];
	} else {
		
		if([self.secondDataSource containsObject:object]) {
			return;
		}
		
		[self.secondDataSource insertObject:object atIndex:indexPath.row];
		[self.secondCollectionView insertItemsAtIndexPaths:@[indexPath]];
	}
}

- (NSIndexPath *)_closestCellIndexPathToPoint:(CGPoint)point inCollectionView:(UICollectionView *)collectionView
{
	NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
	CGFloat minDistance = CGFLOAT_MAX;
	CGRect cellRect = CGRectZero;
	
	for(NSIndexPath *visibleIndexPath in collectionView.indexPathsForVisibleItems) {
		UICollectionViewLayoutAttributes *attributes = [collectionView layoutAttributesForItemAtIndexPath:visibleIndexPath];
		CGPoint center = attributes.center;
		
		CGFloat distance = powf((point.x - center.x), 2) + powf((point.y - center.y), 2);
		
		if(distance < minDistance) {
			minDistance = distance;
			indexPath = visibleIndexPath;
			cellRect = attributes.frame;
		}
	}
	
	CGRect pointRect = CGRectMake(point.x - CGRectGetWidth(cellRect)/2.0f,
								  point.y - CGRectGetHeight(cellRect)/2.0f,
								  CGRectGetWidth(cellRect),
								  CGRectGetHeight(cellRect));
	
	if (!CGRectIntersectsRect(pointRect, cellRect)) {
		return nil;
	}
	
	return indexPath;
}

@end
