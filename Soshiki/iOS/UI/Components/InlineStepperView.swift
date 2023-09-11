//
//  InlineStepperView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/27/23.
//

import UIKit

class InlineStepperView: UIView, UITextFieldDelegate {
    var value: Double
    let range: ClosedRange<Double>
    let step: Double.Stride
    let allowsCustomInput: Bool
    let valueDidChange: (Double) -> Void

    init(
        initialValue: Double,
        range: ClosedRange<Double>,
        step: Double.Stride,
        allowsCustomInput: Bool = true,
        valueDidChange: @escaping (Double) -> Void
    ) {
        self.value = initialValue
        self.range = range
        self.step = step
        self.allowsCustomInput = allowsCustomInput
        self.valueDidChange = valueDidChange
        super.init(frame: .zero)

        let downButton = UIButton()
        downButton.setImage(UIImage(systemName: "minus"), for: .normal)
        downButton.addTarget(self, action: #selector(downStep), for: .touchUpInside)
        downButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(downButton)
        downButton.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true

        let upButton = UIButton()
        upButton.setImage(UIImage(systemName: "plus"), for: .normal)
        upButton.addTarget(self, action: #selector(upStep), for: .touchUpInside)
        upButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(upButton)
        upButton.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true

        let textField = UITextField(frame: .zero)
        textField.keyboardType = .decimalPad
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textField)
        textField.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true

        heightAnchor.constraint(equalToConstant: 29).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func downStep() {
        if value - step >= range.lowerBound {
            value -= step
            valueDidChange(value)
        }
    }

    @objc func upStep() {
        if value + step <= range.lowerBound {
            value += step
            valueDidChange(value)
        }
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool { allowsCustomInput }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        string.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if let num = textField.text.flatMap({ Double($0) }) {
            value = num
            valueDidChange(num)
        } else {
            textField.text = value.toTruncatedString()
        }
    }
}
