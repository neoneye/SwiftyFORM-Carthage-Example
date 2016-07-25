// MIT license. Copyright (c) 2016 SwiftyFORM. All rights reserved.
import UIKit

/*
one-finger pan to adjust slider
two-finger pinch to adjust zoom
*/
class PrecisionSlider: UIView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UIScrollViewDelegate, UIGestureRecognizerDelegate {
	var originalScale: Double = 1.0
	var originalValue: Double?
	
	var model = PrecisionSlider_InnerModel()
	
	typealias ValueDidChange = Void -> Void
	var valueDidChange: ValueDidChange?
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}
	
	func commonInit() {
		addSubview(collectionView)
		addSubview(leftCoverView)
		addSubview(rightCoverView)
		addGestureRecognizer(pinchGestureRecognizer)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		collectionView.frame = bounds
		
		let halfWidth = round(bounds.width/2)-1
		collectionView.contentInset = UIEdgeInsets(top: 0, left: halfWidth, bottom: 0, right: halfWidth)
		
		let (leftFrame, rightFrame) = bounds.divide(round(bounds.width/2), fromEdge: .MinXEdge)
		leftCoverView.frame = CGRect(x: leftFrame.origin.x, y: leftFrame.origin.y, width: leftFrame.size.width - 1, height: leftFrame.size.height)
		rightCoverView.frame = rightFrame
	}
	
	lazy var leftCoverView: UIView = {
		let instance = UIView()
		instance.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
		instance.userInteractionEnabled = false
		return instance
	}()
	
	lazy var rightCoverView: UIView = {
		let instance = UIView()
		instance.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
		instance.userInteractionEnabled = false
		return instance
	}()
	
	var value: Double? {
		let scale = model.lengthOfFullItem
		if scale < 0.1 {
			return nil
		}
		
		let midX: CGFloat = collectionView.contentOffset.x + collectionView.contentInset.left
		var result = Double(midX) / scale + model.minimumValue
		if result < model.minimumValue {
			result = model.minimumValue
		}
		if result > model.maximumValue {
			result = model.maximumValue
		}
		return result
	}
	
	func setValue(value: Double, animated: Bool) {
		let scale = model.lengthOfFullItem
		if scale < 0.1 {
			return
		}
		
		var clampedValue = value
		if clampedValue < model.minimumValue {
			clampedValue = model.minimumValue
		}
		if clampedValue > model.maximumValue {
			clampedValue = model.maximumValue
		}
		
		let valueAdjusted = clampedValue - model.minimumValue
		let contentInsetLet = Double(collectionView.contentInset.left)
		let offsetX = CGFloat(round((scale * valueAdjusted) - contentInsetLet))
		//print("offsetX: \(offsetX)    [ \(scale) * \(valueAdjusted) - \(contentInsetLet) ]")
		
		let originalValueDidChange = valueDidChange
		valueDidChange = nil
		collectionView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: animated)
		valueDidChange = originalValueDidChange
	}
	
	lazy var pinchGestureRecognizer: UIPinchGestureRecognizer = {
		let instance = UIPinchGestureRecognizer(target: self, action: #selector(PrecisionSlider.handlePinch))
		instance.delegate = self
		return instance
	}()
	
	func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}
	
	func handlePinch(gesture: UIPinchGestureRecognizer) {
		if gesture.state == .Began {
			originalScale = model.scale
			originalValue = self.value
		}
		if gesture.state == .Changed {
			var scale = originalScale * Double(gesture.scale)
			if scale < 0.0 {
				scale = 0.01
			}
			model.scale = scale
			
			layout.itemSize = computeItemSize()
			layout.invalidateLayout()
			
			if let value = originalValue {
				setValue(value, animated: false)
			}
			
			valueDidChange?()
		}
	}
	
	func computeItemSize() -> CGSize {
		return CGSize(width: CGFloat(model.lengthOfFullItem), height: PrecisionSlider_InnerModel.height)
	}
	
	lazy var layout: PrecisionSlider_InnerCollectionViewFlowLayout = {
		let instance = PrecisionSlider_InnerCollectionViewFlowLayout()
		instance.scrollDirection = .Horizontal
		instance.minimumInteritemSpacing = 0
		instance.minimumLineSpacing = 0
		instance.sectionInset = UIEdgeInsetsZero
		instance.headerReferenceSize = CGSizeZero
		instance.footerReferenceSize = CGSizeZero
		instance.itemSize = self.computeItemSize()
		instance.model = self.model
		return instance
	}()
	
	lazy var collectionView: UICollectionView = {
		let instance = UICollectionView(frame: CGRectZero, collectionViewLayout: self.layout)
		instance.showsHorizontalScrollIndicator = false
		instance.showsVerticalScrollIndicator = false
		instance.backgroundColor = UIColor.blackColor()
		instance.bounces = false
		instance.alwaysBounceHorizontal = true
		instance.alwaysBounceVertical = false
		instance.registerClass(PrecisionSlider_InnerCollectionViewCell.self, forCellWithReuseIdentifier: PrecisionSlider_InnerCollectionViewCell.identifier)
		instance.contentInset = UIEdgeInsetsZero
		instance.delegate = self
		instance.dataSource = self
		return instance
	}()
	
	func scrollViewDidScroll(scrollView: UIScrollView) {
		valueDidChange?()
	}
	
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		var count = model.numberOfFullItems
		if model.hasOnePartialItem {
			count += 1
		}
		if model.hasPartialItemBefore {
			count += 1
		}
		if model.hasPartialItemAfter {
			count += 1
		}
		//print("number of items: \(count)")
		return count
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(PrecisionSlider_InnerCollectionViewCell.identifier, forIndexPath: indexPath) as! PrecisionSlider_InnerCollectionViewCell
		
		let index = Int(floor(model.minimumValue)) + indexPath.row
		var displayValue = index % 10
		if displayValue < 0 {
			displayValue += 10
		}
		cell.label.text = String(displayValue)
		return cell
	}
	
	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
		if model.hasOnePartialItem {
			let size = CGSize(
				width: CGFloat(model.lengthOfOnePartialItem),
				height: PrecisionSlider_InnerModel.height
			)
			//print("size for one-partial \(indexPath.row) \(size.width)")
			return size
		}
		var row = indexPath.row
		if model.hasPartialItemBefore {
			if row == 0 {
				let size = CGSize(
					width: CGFloat(model.lengthOfPartialItemBefore),
					height: PrecisionSlider_InnerModel.height
				)
				//print("size for partial-before \(indexPath.row) \(size.width)")
				return size
			}
			row -= 1
		}
		if row >= model.numberOfFullItems {
			if model.hasPartialItemAfter {
				let size = CGSize(
					width: CGFloat(model.lengthOfPartialItemAfter),
					height: PrecisionSlider_InnerModel.height
				)
				//print("size for partial-after \(indexPath.row) \(size.width)")
				return size
			}
		}
		let size = CGSize(
			width: CGFloat(model.lengthOfFullItem),
			height: PrecisionSlider_InnerModel.height
		)
		//print("size for full \(indexPath.row) \(size.width)")
		return size
	}
}


// MARK: - Classes used internally by PrecisionSlider

class PrecisionSlider_InnerModel: CustomDebugStringConvertible {
	var minimumValue: Double = 0.0
	var maximumValue: Double = 100.0
	
	/*
	This is used when the range is tiny and doesn't cross any integer boundary.
	Example of such a range: from min=0.4 to max=0.6
	here the size of the range is 0.2, which is (max - min)
	*/
	var hasOnePartialItem = false
	var sizeOfOnePartialItem: Double = 0.0
	
	/*
	This is used when the range-start crosses an integer boundary.
	Example of such a range: from min=0.7 to max=3.3
	In this case there will be a partial-item-before
	with the range from min=0.7 to max=1.0
	here the size of the range is 0.3  (max - min)
	*/
	var hasPartialItemBefore = false
	var sizeOfPartialItemBefore: Double = 0.0
	
	/*
	This is used when the range is crossing zero or more integer boundaries.
	Example of such a range: from min=0.7 to max=3.3
	In this case there will be a full items will span from min=1.0 to max=3.0
	here the number of full items is 2  (max - min)
	The size of a full item is alway 1, since it's full.
	*/
	var numberOfFullItems = 100
	
	/*
	This is used when the range-end crosses an integer boundary.
	Example of such a range: from min=0.7 to max=3.3
	In this case there will be a partial-item-after
	with the range from min=3.0 to max=3.3
	here the size of the range is 0.3  (max - min)
	*/
	var hasPartialItemAfter = false
	var sizeOfPartialItemAfter: Double = 0.0
	
	var scale: Double = 60.0
	
	var lengthOfFullItem: Double {
		let result = ceil(scale)
		if result < 0.1 {
			return 0.1
		}
		return result
	}
	
	var lengthOfAllFullItems: Double {
		return Double(numberOfFullItems) * lengthOfFullItem
	}
	var lengthOfOnePartialItem: Double {
		return ceil(lengthOfFullItem * sizeOfOnePartialItem)
	}
	var lengthOfPartialItemBefore: Double {
		return ceil(lengthOfFullItem * sizeOfPartialItemBefore)
	}
	var lengthOfPartialItemAfter: Double {
		return ceil(lengthOfFullItem * sizeOfPartialItemAfter)
	}
	
	static let height: CGFloat = 130
	
	var debugDescription: String {
		var strings = [String]()
		strings.append(String(format: "range: %.5f %.5f", minimumValue, maximumValue))
		if hasOnePartialItem {
			strings.append(String(format: "one-partial: %.5f", sizeOfOnePartialItem))
		}
		if hasPartialItemBefore {
			strings.append(String(format: "partial-before: %.5f", sizeOfPartialItemBefore))
		}
		strings.append("full: \(numberOfFullItems)")
		if hasPartialItemAfter {
			strings.append(String(format: "partial-after: %.5f", sizeOfPartialItemAfter))
		}
		return strings.joinWithSeparator(" , ")
	}
}

class PrecisionSlider_InnerCollectionViewFlowLayout: UICollectionViewFlowLayout {
	weak var model: PrecisionSlider_InnerModel?
	
	override func collectionViewContentSize() -> CGSize {
		guard let model = self.model else {
			print("no model")
			return CGSizeZero
		}
		
		var length: Double = 0
		if model.hasOnePartialItem {
			length += model.lengthOfOnePartialItem
		}
		if model.hasPartialItemBefore {
			length += model.lengthOfPartialItemBefore
		}
		length += model.lengthOfAllFullItems
		if model.hasPartialItemAfter {
			length += model.lengthOfPartialItemAfter
		}
		// Add 1 so the value can reach max and beyond. Otherwise the value cannot quite reach max.
		length += 1
		
		return CGSize(width: CGFloat(length), height: PrecisionSlider_InnerModel.height)
	}
}

class PrecisionSlider_InnerCollectionViewCell: UICollectionViewCell {
	static let identifier = "cell"
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}
	
	func commonInit() {
		backgroundColor = UIColor.whiteColor()
		addSubview(leftBorder)
		addSubview(label)
	}
	
	lazy var leftBorder: UIView = {
		let instance = UIView()
		instance.backgroundColor = UIColor.blackColor()
		return instance
	}()
	
	lazy var label: UILabel = {
		let instance = UILabel()
		instance.text = "0"
		return instance
	}()
	
	override func layoutSubviews() {
		super.layoutSubviews()
		leftBorder.frame = CGRect(x: 0, y: 0, width: 1, height: bounds.height)
		
		let labelHidden = self.bounds.width < 30
		label.hidden = labelHidden
		
		label.sizeToFit()
		let labelFrame = label.frame
		label.frame = CGRect(x: 7, y: 5, width: bounds.width - 10, height: labelFrame.height)
	}
}
