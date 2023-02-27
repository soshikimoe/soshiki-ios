//
//  SettingItemTableViewCell.swift
//  Soshiki
//
//  Created by Jim Phieffer on 2/5/23.
//

import UIKit

class SettingItemTableViewCell: UITableViewCell {
    var viewControllerToPresent: UIViewController?

    var item: any SettingItem

    init(item: any SettingItem) {
        self.item = item
        switch item {
        case let item as TextSettingItem:
            super.init(style: .default, reuseIdentifier: "TextSettingItemTableViewCell")
            let titleLabel = UILabel()
            titleLabel.text = item.title
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(titleLabel)
            titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
            titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
            let dividerView = UIView()
            dividerView.backgroundColor = .separator
            dividerView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(dividerView)
            dividerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
            dividerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
            dividerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8).isActive = true
            dividerView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
            let textField = UITextField()
            textField.text = item.value
            textField.placeholder = item.placeholder
            textField.delegate = self
            textField.returnKeyType = .done
            textField.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(textField)
            textField.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
            textField.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
            textField.topAnchor.constraint(equalTo: dividerView.bottomAnchor, constant: 8).isActive = true
            textField.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
            self.selectionStyle = .none
        case let item as ToggleSettingItem:
            super.init(style: .default, reuseIdentifier: "ToggleSettingItemTableViewCell")
            var content = self.defaultContentConfiguration()
            content.text = item.title
            let toggleView = UISwitch()
            toggleView.isOn = item.value
            toggleView.addTarget(self, action: #selector(updateToggleFilter(_:)), for: .valueChanged)
            self.accessoryView = toggleView
            self.contentConfiguration = content
            self.selectionStyle = .none
        case let item as SegmentSettingItem:
            super.init(style: .default, reuseIdentifier: "SegmentSettingItemTableViewCell")
            let titleLabel = UILabel()
            titleLabel.text = item.title
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(titleLabel)
            titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
            titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
            let segmentView = UISegmentedControl(items: item.options)
            segmentView.selectedSegmentIndex = item.options.firstIndex(of: item.value) ?? 0
            segmentView.isSpringLoaded = true
            segmentView.addTarget(self, action: #selector(updateSegmentFilter(_:)), for: .valueChanged)
            segmentView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(segmentView)
            segmentView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
            segmentView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
            segmentView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8).isActive = true
            segmentView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        case let item as SelectSettingItem:
            super.init(style: .default, reuseIdentifier: "SelectSettingItemTableViewCell")
            var content = self.defaultContentConfiguration()
            content.text = item.title
            self.accessoryType = .disclosureIndicator
            self.contentConfiguration = content
            self.viewControllerToPresent = StringSelectViewController(
                title: item.title,
                options: item.options,
                selected: item.value,
                indicatorType: .includeExclude
            ) { value in
                item.value = value
                item.valueDidChange(value)
            }
        case let item as ExcludableSelectSettingItem:
            super.init(style: .default, reuseIdentifier: "ExcludableSelectSettingItemTableViewCell")
            var content = self.defaultContentConfiguration()
            content.text = item.title
            self.accessoryType = .disclosureIndicator
            self.contentConfiguration = content
            self.viewControllerToPresent = StringSelectViewController(
                title: item.title,
                options: item.options,
                selected: item.value,
                indicatorType: .includeExclude
            ) { value in
                item.value = value
                item.valueDidChange(value)
            }
        case let item as MultiSelectSettingItem:
            super.init(style: .default, reuseIdentifier: "MultiSelectSettingItemTableViewCell")
            var content = self.defaultContentConfiguration()
            content.text = item.title
            self.accessoryType = .disclosureIndicator
            self.contentConfiguration = content
            self.viewControllerToPresent = StringSelectViewController(
                title: item.title,
                options: item.options,
                selected: item.value
            ) { value in
                item.value = value
                item.valueDidChange(value)
            }
        case let item as ExcludableMultiSelectSettingItem:
            super.init(style: .default, reuseIdentifier: "ExcludableMultiSelectSettingItemTableViewCell")
            var content = self.defaultContentConfiguration()
            content.text = item.title
            self.accessoryType = .disclosureIndicator
            self.contentConfiguration = content
            self.viewControllerToPresent = StringSelectViewController(
                title: item.title,
                options: item.options,
                selected: item.value
            ) { value in
                item.value = value
                item.valueDidChange(value)
            }
        case let item as NumberSettingItem:
            super.init(style: .value1, reuseIdentifier: "NumberSettingItemTableViewCell")
            var content = self.defaultContentConfiguration()
            content.text = item.title
            content.secondaryText = item.value.toTruncatedString()
            let stepperView = UIStepper()
            stepperView.minimumValue = item.lowerBound
            stepperView.maximumValue = item.upperBound
            stepperView.value = item.value
            stepperView.stepValue = item.step
            stepperView.addTarget(self, action: #selector(updateNumberFilter(_:)), for: .valueChanged)
            self.accessoryView = stepperView
            self.contentConfiguration = content
            self.selectionStyle = .none
        case let item as ButtonSettingItem:
            super.init(style: .default, reuseIdentifier: "ButtonSettingItemTableViewCell")
            var content = self.defaultContentConfiguration()
            content.text = item.title
            if item.presentsView {
                self.accessoryType = .disclosureIndicator
                content.textProperties.color = .label
            } else {
                self.accessoryType = .none
                content.textProperties.color = .tintColor
            }
            self.contentConfiguration = content
        default:
            super.init(style: .default, reuseIdentifier: "SettingItemTableViewCell")
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func didSelect() {
        if let viewControllerToPresent {
            self.nearestNavigationController?.pushViewController(viewControllerToPresent, animated: true)
        } else if let item = item as? ButtonSettingItem {
            item.valueDidChange(())
        }
    }

    @objc func updateToggleFilter(_ sender: UISwitch) {
        guard let item = item as? ToggleSettingItem else { return }
        item.value = sender.isOn
        item.valueDidChange(sender.isOn)
    }

    @objc func updateSegmentFilter(_ sender: UISegmentedControl) {
        guard let item = item as? SegmentSettingItem else { return }
        item.value = item.options[sender.selectedSegmentIndex]
        item.valueDidChange(item.options[sender.selectedSegmentIndex])
    }

    @objc func updateNumberFilter(_ sender: UIStepper) {
        guard let item = item as? NumberSettingItem else { return }
        item.value = sender.value
        item.valueDidChange(sender.value)
        var content = self.contentConfiguration as? UIListContentConfiguration ?? self.defaultContentConfiguration()
        content.secondaryText = item.value.toTruncatedString()
        self.contentConfiguration = content
    }
}

extension SettingItemTableViewCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let item = item as? TextSettingItem else { return }
        item.value = textField.text ?? ""
        item.valueDidChange(textField.text ?? "")
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
