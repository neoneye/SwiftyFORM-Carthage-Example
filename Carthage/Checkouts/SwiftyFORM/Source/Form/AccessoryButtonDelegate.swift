// MIT license. Copyright (c) 2015 SwiftyFORM. All rights reserved.
import UIKit

@objc public protocol AccessoryButtonDelegate {
	func form_accessoryButtonTapped(indexPath: NSIndexPath, tableView: UITableView)
}
