//
//  WelcomeViewController.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/20.
//

import UIKit
import Combine
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonSDK

final class WelcomeViewController: UIViewController {
    
    private enum Constants {
        static let topAnchorInset: CGFloat = 20
        static let DemoIntroKeyName = "should_show_demo_video"
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        authenticationStateTask = Task { [weak self] in
            guard let stateStream = self?.authenticationViewModel.stateStream else { return }
            for await authenticationState in stateStream {
                self?.didEnter(authenticationState)
            }
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let authenticationViewModel = AuthenticationViewModel()
    private var authenticationStateTask: Task<(), Never>?
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    private(set) lazy var viewModel = WelcomeViewModel()
    
    let welcomeIllustrationView = WelcomeIllustrationView()
    
    //TODO: Extract all those UI-elements in a UIView-subclass
    private(set) lazy var dismissBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(WelcomeViewController.dismissBarButtonItemDidPressed(_:)))
    
    let buttonContainer = UIStackView()

    private(set) lazy var pickOtherServerButton: UIButton = {

        var buttonConfiguration = UIButton.Configuration.filled()
        buttonConfiguration.attributedTitle = AttributedString(
            L10n.Scene.Register.title,
            attributes: .init([.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))])
        )

        buttonConfiguration.background.cornerRadius = 14
        buttonConfiguration.baseBackgroundColor = .white
        buttonConfiguration.baseForegroundColor = .black

        buttonConfiguration.contentInsets = .init(top: WelcomeViewController.actionButtonPadding.top,
                                                  leading: WelcomeViewController.actionButtonPadding.left,
                                                  bottom: WelcomeViewController.actionButtonPadding.bottom,
                                                  trailing: WelcomeViewController.actionButtonPadding.right)

        let button = UIButton(configuration: buttonConfiguration)

        return button
    }()

    private(set) lazy var signInButton: UIButton = {
        var buttonConfiguration = UIButton.Configuration.plain()
        buttonConfiguration.baseForegroundColor = .white
        buttonConfiguration.attributedTitle = AttributedString(
            L10n.Scene.Welcome.logIn,
            attributes: .init([.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))])
        )

        let button = UIButton(configuration: buttonConfiguration)
        return button
    }()
}

extension WelcomeViewController {
    private func displayError(_ error: Error) {
        let alertController = UIAlertController(for: error, title: "Error", preferredStyle: .alert)
        let okAction = UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default, handler: nil)
        alertController.addAction(okAction)
        _ = self.sceneCoordinator?.present(
            scene: .alertController(alertController: alertController),
            from: nil,
            transition: .alertController(animated: true, completion: nil)
        )
    }
    
    private func didEnter(_ state: AuthenticationViewModel.State) {
        switch state {
        case .initial:
            break
        case .error(let error):
            displayError(error)
        case .logInToExistingAccountRequested:
            _ = self.sceneCoordinator?.present(scene: .mastodonLogin(authenticationViewModel: authenticationViewModel, suggestedDomain: viewModel.randomDefaultServer?.domain), from: self, transition: .show)
        case .joiningServer:
            break
        case .showingRules(let viewModel):
            if let viewModel {
                _ = self.sceneCoordinator?.present(scene: .mastodonServerRules(viewModel: viewModel), from: self, transition: .show)
            } else {
                popBack()
            }
        case .registering(let viewModel):
            _ = self.sceneCoordinator?.present(scene: .mastodonRegister(viewModel: viewModel), from: self, transition: .show)
        case .showingPrivacyPolicy(let viewModel):
            _ = self.sceneCoordinator?.present(scene: .mastodonPrivacyPolicies(viewModel: viewModel), from: self, transition: .show)
        case .pickingServer:
            _ = self.sceneCoordinator?.present(scene: .mastodonPickServer(viewMode: MastodonPickServerViewModel(joinServer: { [weak self] server in try await self?.authenticationViewModel.joinServer(server) }, displayError: { [weak self] error in self?.displayError(error) })), from: self, transition: .show)
        case .confirmingEmail(let viewModel):
            _ = self.sceneCoordinator?.present(scene: .mastodonConfirmEmail(viewModel: viewModel), from: self, transition: .show)
        case .authenticatedUser(let authBox):
            self.sceneCoordinator?.setup()
            break
        case .authenticatingUser:
            break
        }
    }
    
    private func popBack() {
        navigationController?.popViewController(animated: true)
    }
}

extension WelcomeViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        definesPresentationContext = true
        preferredContentSize = CGSize(width: 547, height: 678)
        
        navigationController?.navigationBar.prefersLargeTitles = true /// enable large title support for this and all subsequent VCs
        navigationItem.largeTitleDisplayMode = .never
        
        view.overrideUserInterfaceStyle = .light
        
        setupOnboardingAppearance()

        view.addSubview(welcomeIllustrationView)
        welcomeIllustrationView.translatesAutoresizingMaskIntoConstraints = false

        buttonContainer.axis = .vertical
        buttonContainer.spacing = 8
        buttonContainer.isLayoutMarginsRelativeArrangement = true
        
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonContainer)
        NSLayoutConstraint.activate([
            buttonContainer.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            buttonContainer.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            view.layoutMarginsGuide.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),
        ])

        pickOtherServerButton.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addArrangedSubview(pickOtherServerButton)
        NSLayoutConstraint.activate([
            pickOtherServerButton.heightAnchor.constraint(greaterThanOrEqualToConstant: WelcomeViewController.actionButtonHeight)
        ])

        signInButton.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addArrangedSubview(signInButton)
        NSLayoutConstraint.activate([
            signInButton.heightAnchor.constraint(greaterThanOrEqualToConstant: WelcomeViewController.actionButtonHeight)
        ])

        pickOtherServerButton.addTarget(self, action: #selector(pickOtherServerTapped(_:)), for: .touchUpInside)
        signInButton.addTarget(self, action: #selector(signIn(_:)), for: .touchUpInside)

        view.backgroundColor = Asset.Scene.Welcome.Illustration.backgroundGreen.color
        
        viewModel.$needsShowDismissEntry
            .receive(on: DispatchQueue.main)
            .sink { [weak self] needsShowDismissEntry in
                guard let self = self else { return }
                self.navigationItem.leftBarButtonItem = needsShowDismissEntry ? self.dismissBarButtonItem : nil
            }
            .store(in: &disposeBag)

        setupIllustrationLayout()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        view.layoutIfNeeded()
    }
    
    private var computedTopAnchorInset: CGFloat {
        (navigationController?.navigationBar.bounds.height ?? UINavigationBar().bounds.height) + Constants.topAnchorInset
    }
}

extension WelcomeViewController {

    private func updateButtonContainerLayoutMargins(traitCollection: UITraitCollection) {
        switch traitCollection.userInterfaceIdiom {
        case .phone:
            buttonContainer.layoutMargins = UIEdgeInsets(
                top: 0,
                left: WelcomeViewController.actionButtonMargin,
                bottom: WelcomeViewController.viewBottomPaddingHeight,
                right: WelcomeViewController.actionButtonMargin
            )
        default:
            let margin = traitCollection.horizontalSizeClass == .regular ? WelcomeViewController.actionButtonMarginExtend : WelcomeViewController.actionButtonMargin
            buttonContainer.layoutMargins = UIEdgeInsets(
                top: 0,
                left: margin,
                bottom: WelcomeViewController.viewBottomPaddingHeightExtend,
                right: margin
            )
        }
    }
    
    private func setupIllustrationLayout() {
        welcomeIllustrationView.setup()
    }
}

extension WelcomeViewController {
    
    private func joinServer(_ server: Mastodon.Entity.Server) {
        Task {
            do {
                try await authenticationViewModel.joinServer(server)
            } catch let error {
                displayError(error)
            }
        }
    }

    //MARK: - Actions
    @objc
    private func pickOtherServerTapped(_ sender: UIButton) {
        authenticationViewModel.pickServer()
    }
    
    @objc
    private func signIn(_ sender: UIButton) {
        authenticationViewModel.logInRequested()
    }

    @objc
    private func learnMore(_ sender: UIButton) {
        let educationViewController = EducationViewController()
        educationViewController.modalPresentationStyle = .pageSheet

        if let sheetPresentationController = educationViewController.sheetPresentationController {
            sheetPresentationController.detents = [.medium()]
            sheetPresentationController.prefersGrabberVisible = true
        }

        present(educationViewController, animated: true)
    }

    @objc
    private func dismissBarButtonItemDidPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - OnboardingViewControllerAppearance
extension WelcomeViewController: OnboardingViewControllerAppearance {}

// MARK: - UIAdaptivePresentationControllerDelegate
extension WelcomeViewController: UIAdaptivePresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        
        // update button layout
        updateButtonContainerLayoutMargins(traitCollection: traitCollection)
        
        let navigationController = navigationController as? OnboardingNavigationController
        
        switch traitCollection.userInterfaceIdiom {
        case .phone:
            navigationController?.gradientBorderView.isHidden = true
            // make underneath view controller alive to fix layout issue due to view life cycle
            return .fullScreen
        default:
            switch traitCollection.horizontalSizeClass {
            case .compact:
                navigationController?.gradientBorderView.isHidden = true
                return .fullScreen
            default:
                navigationController?.gradientBorderView.isHidden = false
                return .formSheet
            }
        }
    }
    
    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        return nil
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }
}

//MARK: - UICollectionViewDelegate
extension WelcomeViewController: UICollectionViewDelegate { }
