//
//  ViewController.swift
//  iOSReleaseTest
//
//  Created by Nipun Singh on 2/4/22.
//

import UIKit
import BranchSDK

/// Root screen of each scene. Scene 1 loads it from Main.storyboard; Scene 2 creates it in code.
class ViewController: UIViewController {

    /// Shown at the top of the screen. Set before the view loads.
    var sceneName = "Scene 1"

    private let titleLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = sceneName == "Scene 1" ? .systemBackground : .systemTeal.withAlphaComponent(0.15)

        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.text = sceneName
        titleLabel.accessibilityIdentifier = sceneName == "Scene 1" ? "sceneTitle-scene1" : "sceneTitle-scene2"

        let stack = UIStackView(arrangedSubviews: [titleLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        if sceneName == "Scene 1" {
            let openSceneButton = UIButton(type: .system)
            openSceneButton.setTitle("Open Scene 2", for: .normal)
            openSceneButton.accessibilityIdentifier = "openScene2"
            openSceneButton.addAction(UIAction { _ in SceneKind.openSecondary() }, for: .touchUpInside)
            if !UIApplication.shared.supportsMultipleScenes {
                openSceneButton.isEnabled = false
                openSceneButton.setTitle("Open Scene 2 (needs multiple windows, e.g. iPad)", for: .disabled)
            }
            stack.addArrangedSubview(openSceneButton)
        }

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
        ])
    }
}
