//
//  PlayerComponentViewController.swift
//  shirkers-challenge
//
//  Created by Artur Carneiro on 08/09/20.
//  Copyright © 2020 Artur Carneiro. All rights reserved.
//

import UIKit
import os.log

/// Representation of the Player Component. Should be instantiated only once as part
/// of the `RootViewController`.
final class PlayerComponentViewController: UIViewController {

    // MARK: - Properties
    /// The slider representing the progress of the audio playback.
    @AutoLayout private var progressSlider: MemoraSlider
    /// The timestamp of the audio's duration.
    @AutoLayout private var timestampLabel: UILabel
    /// The creation data of the audio.
    @AutoLayout private var creationDateLabel: UILabel
    /// The title of the audio.
    @AutoLayout private var titleLabel: UILabel
    /// The play button used to control the component.
    @AutoLayout private var playButton: UIButton
    /// The view used to encapsulate all the views. Used to more easily configure
    /// constraints with its superview (`RootViewController.view`).
    @AutoLayout private var contentView: UIView

    private let viewModel: PlayerComponentViewModel

    // MARK: - Init
    init(viewModel: PlayerComponentViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        os_log("PlayerComponentViewController initialized.", log: .appFlow, type: .debug)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureLabels()
        configurePlayButton()
        configureLayout()
        viewModel.delegate = self

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didChangeTheme(_:)),
                                               name: Notification.Name("theme-changed"),
                                               object: nil)
    }

    // MARK: - @objc
    @objc private func didChangeTheme(_ notification: NSNotification) {
        os_log("PlayerComponentViewController should change theme.", log: .appFlow, type: .debug)
        timestampLabel.textColor = .memoraAccent
        creationDateLabel.textColor = .memoraAccent
        titleLabel.textColor = .memoraAccent
        playButton.tintColor = .memoraAccent
        progressSlider.tintColor = .memoraAccent
        progressSlider.minimumTrackTintColor = .memoraAccent
        progressSlider.maximumTrackTintColor = .memoraAccent
        contentView.backgroundColor = .memoraFill
        view.backgroundColor = .memoraFill
    }

    @objc private func didTapPlay(_ button: MemoraButton) {
        if viewModel.isPlaying {
            viewModel.stop()
        } else {
            viewModel.play()
        }
    }

    @objc private func didStartSeek(_ slider: MemoraSlider) {
        viewModel.seekTo(slider.value)
    }

    // MARK: - Layout
    /// Configures the main view.
    private func configureView() {
        view.backgroundColor = .memoraFill
        view.layer.cornerRadius = view.frame.height * 0.015
    }

    /// Configures all the labels.
    private func configureLabels() {
        timestampLabel.textColor = .memoraAccent
        timestampLabel.font = .preferredFont(forTextStyle: .body)
        timestampLabel.text = "-"

        creationDateLabel.textColor = .memoraAccent
        creationDateLabel.font = .preferredFont(forTextStyle: .body)
        creationDateLabel.text = "-"

        titleLabel.textColor = .memoraAccent
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title2).bold()
        titleLabel.minimumScaleFactor = 0.5
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.numberOfLines = 2
        titleLabel.text = "-"

        progressSlider.maximumValue = 100
        progressSlider.minimumValue = 0.0
        progressSlider.addTarget(self, action: #selector(didStartSeek(_:)), for: .valueChanged)
    }

    /// Configures the play button.
    private func configurePlayButton() {
        playButton.setImage(UIImage(systemName: "play.fill",
                                    withConfiguration: UIImage.SymbolConfiguration(textStyle: .title2)),
                            for: .normal)
        playButton.tintColor = .memoraAccent
        playButton.addTarget(self, action: #selector(didTapPlay(_:)), for: .touchUpInside)
    }

    /// Configures the layout using the `contentView`.
    private func configureLayout() {
        contentView.addSubview(progressSlider)
        contentView.addSubview(timestampLabel)
        contentView.addSubview(creationDateLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(playButton)

        view.addSubview(contentView)

        let rootLayoutMarginsGuide = view.layoutMarginsGuide
        let contentLayoutMarginsGuide = contentView.layoutMarginsGuide

        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalTo: rootLayoutMarginsGuide.widthAnchor,
                                              multiplier: DesignSystem.PlayerComponent.widthMultiplier),
            contentView.centerXAnchor.constraint(equalTo: rootLayoutMarginsGuide.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: rootLayoutMarginsGuide.centerYAnchor),

            progressSlider.topAnchor.constraint(equalTo: contentLayoutMarginsGuide.topAnchor),
            progressSlider.widthAnchor.constraint(equalTo: contentLayoutMarginsGuide.widthAnchor),
            progressSlider.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.2),
            progressSlider.centerXAnchor.constraint(equalTo: contentLayoutMarginsGuide.centerXAnchor),

            timestampLabel.topAnchor.constraint(equalTo: progressSlider.bottomAnchor,
                                                constant: DesignSystem.PlayerComponent.spacingFromProgressSlider),
            timestampLabel.leadingAnchor.constraint(equalTo: contentLayoutMarginsGuide.leadingAnchor),

            creationDateLabel.topAnchor.constraint(equalTo: progressSlider.bottomAnchor,
                                                   constant: DesignSystem.PlayerComponent.spacingFromProgressSlider),
            creationDateLabel.trailingAnchor.constraint(equalTo: contentLayoutMarginsGuide.trailingAnchor),

            titleLabel.topAnchor.constraint(equalTo: timestampLabel.bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentLayoutMarginsGuide.leadingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentLayoutMarginsGuide.bottomAnchor),
            titleLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor,
                                              multiplier: 0.8),

            playButton.topAnchor.constraint(equalTo: creationDateLabel.bottomAnchor),
            playButton.trailingAnchor.constraint(equalTo: contentLayoutMarginsGuide.trailingAnchor),
            playButton.bottomAnchor.constraint(equalTo: contentLayoutMarginsGuide.bottomAnchor)
        ])
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
        os_log("PlayerComponentViewController deinitialized.", log: .appFlow, type: .debug)
    }
}

// MARK: - ViewModel Delegate
extension PlayerComponentViewController: PlayerComponentViewModelDelegate {
    func update() {
        playButton.setImage(viewModel.isPlaying ? UIImage(systemName: "stop.fill") : UIImage(systemName: "play.fill"), for: .normal)
        timestampLabel.text = viewModel.currentTimestamp
        creationDateLabel.text = viewModel.createdAt
        titleLabel.text = viewModel.title
        progressSlider.value = viewModel.currentPos
    }
}
