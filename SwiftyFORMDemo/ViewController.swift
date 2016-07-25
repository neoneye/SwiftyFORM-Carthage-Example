// MIT license. Copyright (c) 2016 SwiftyFORM. All rights reserved.
import SwiftyFORM

class ViewController: FormViewController {
	override func populate(builder: FormBuilder) {
		builder.navigationTitle = "Hello World"
		builder += SectionHeaderTitleFormItem(title: "It works!")
		builder += StaticTextFormItem().title("Title 0").value("Value 0")
		builder += StaticTextFormItem().title("Title 1").value("Value 1")
		builder += StaticTextFormItem().title("Title 2").value("Value 2")
	}
}
