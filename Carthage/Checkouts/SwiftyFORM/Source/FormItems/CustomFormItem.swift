// MIT license. Copyright (c) 2015 SwiftyFORM. All rights reserved.
import Foundation

public class CustomFormItem: FormItem {
	public struct Context {
		public let viewController: UIViewController
	}
	
	public enum CustomFormItemError: ErrorType {
		case CouldNotCreate
	}

	public typealias CreateCell = Context throws -> UITableViewCell
	public var createCell: CreateCell = { _ in throw CustomFormItemError.CouldNotCreate }
	
	override func accept(visitor: FormItemVisitor) {
		visitor.visitCustom(self)
	}
}
