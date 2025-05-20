//
//  OnboardingNextView.swift
//  Mastodon
//
//  Created by Nathan Mattes on 2022-12-12.
//

import UIKit
import MastodonUI
import MastodonAsset
import MastodonLocalization

protocol OnboardingNextViewActionProtocol {
    func onPickAnotherServerAction()
    func onCensorshipAction()
}

final class OnboardingNextView: UIView {
    
    static let buttonHeight: CGFloat = 50
        
    var delegate: OnboardingNextViewActionProtocol?
    
    private lazy var container: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .center
        return stackView
    }()

    let nextButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 14
        button.backgroundColor = Asset.Colors.Brand.blurple.color
        button.setTitle(L10n.Common.Controls.Actions.next, for: .normal)
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 16, weight: .bold))
        return button
    }()

    private lazy var pickDifferentServerButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = Asset.Colors.Brand.blurple.color.cgColor
        button.setTitle(L10n.Scene.ServerPicker.switchServerToDiffOneHint, for: .normal)
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 13, weight: .bold))
        button.setTitleColor(Asset.Colors.Brand.blurple.color, for: .normal)
        return button
    }()
    
    private lazy var censorshipButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = Asset.Colors.Brand.blurple.color.cgColor
        button.setTitle(L10n.Scene.ServerPicker.censorshipHint, for: .normal)
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 13, weight: .bold))
        button.setTitleColor(Asset.Colors.Brand.blurple.color, for: .normal)
        button.widthAnchor.constraint(equalToConstant: 60).isActive = true
        return button
    }()
    
    private lazy var hStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        return stackView
    }()
    
    lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    private var isLoading: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

    private func _init() {
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(nextButton)

        hStack.addArrangedSubview(pickDifferentServerButton)
        hStack.addArrangedSubview(censorshipButton)
        
        container.addArrangedSubview(hStack)
        addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 16),
            safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 16),

            nextButton.widthAnchor.constraint(equalTo: container.widthAnchor),
            hStack.widthAnchor.constraint(equalTo: container.widthAnchor),
        ])
        
        NSLayoutConstraint.activate([
            nextButton.heightAnchor.constraint(greaterThanOrEqualToConstant: NavigationActionView.buttonHeight)
        ])
        
        addTargetForPickDifferentServerButton()
        addTargetForCensorshipButton()
    }

    func showLoading() {
        guard isLoading == false else { return }
        nextButton.isEnabled = false
        isLoading = true
        nextButton.setTitle("", for: .disabled)

        nextButton.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: nextButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: nextButton.centerYAnchor),
        ])
        activityIndicator.startAnimating()
    }

    func stopLoading() {
        guard isLoading else { return }
        isLoading = false
        if activityIndicator.superview == nextButton {
            activityIndicator.removeFromSuperview()
        }
        nextButton.isEnabled = true
        nextButton.setTitle(L10n.Common.Controls.Actions.next, for: .disabled)
    }
    
     func addTargetForPickDifferentServerButton() {
         pickDifferentServerButton.addTarget(self, action: #selector(onPickDifferentServerButtonTapped), for: .touchUpInside)
     }
     
     @objc func onPickDifferentServerButtonTapped() {
         delegate?.onPickAnotherServerAction()
     }
    
    func addTargetForCensorshipButton() {
        censorshipButton.addTarget(self, action: #selector(onCensorshipButtonTapped), for: .touchUpInside)
    }
    
    @objc func onCensorshipButtonTapped() {
        ConfigureSettings.Introduction.shouldShowDemoIntroKey = true
        delegate?.onCensorshipAction()
    }
}
