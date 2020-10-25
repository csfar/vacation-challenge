//
//  InboxViewController.swift
//  shirkers-challenge
//
//  Created by Artur Carneiro on 29/08/20.
//  Copyright © 2020 Artur Carneiro. All rights reserved.
//

import UIKit
import os.log

/// Representation of the Inbox screen. Should be instantianted as one the pages of
/// a `UIPageViewController`. 
final class InboxViewController: UIViewController {
    // MARK: - Properties
    /// `UICollectionView` used to display all recordings currently in the Inbox.
    @AutoLayout private var inboxCollectionView: InboxCollectionView

    private lazy var memoryContextViewController: MemoryContextViewController = {
        return MemoryContextViewController(viewModel: MemoryViewModel())
    }()

    ///  The `ViewModel` responsible for this `View`.
    private let viewModel: InboxViewModel
    // MARK: - Init
    /// Initializes a new instance of this type.
    /// - Parameter viewModel: The `ViewModel` responsible for this `View`.
    init(viewModel: InboxViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        os_log("InboxViewController initialized.", log: .appFlow, type: .debug)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViewModel()
        setUpCollectionView()
        title = NSLocalizedString("inbox", comment: "Title of the InboxViewController")
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didChangeTheme(_:)),
                                               name: Notification.Name("theme-changed"),
                                               object: nil)
    }

    // MARK: - @objc
    @objc private func didChangeTheme(_ notification: NSNotification) {
        os_log("InboxViewController should change theme.", log: .appFlow, type: .debug)
        inboxCollectionView.backgroundColor = .memoraBackground
        inboxCollectionView.reloadData()
    }

    // MARK: - ViewModel setup
    private func setUpViewModel() {
        viewModel.delegate = self
        viewModel.requestFetch()
    }

    // MARK: - Layout
    private func setUpCollectionView() {
        inboxCollectionView.delegate = self
        inboxCollectionView.dataSource = self

        inboxCollectionView.register(InboxCollectionViewCell.self,
                                     forCellWithReuseIdentifier: InboxCollectionViewCell.identifier)
        
        view.addSubview(inboxCollectionView)

        NSLayoutConstraint.activate([
            inboxCollectionView.widthAnchor.constraint(equalTo: view.widthAnchor),
            inboxCollectionView.heightAnchor.constraint(equalTo: view.heightAnchor),
            inboxCollectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            inboxCollectionView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
        os_log("InboxViewController deinitialized.", log: .appFlow, type: .debug)
    }
}

// MARK: - UICollectionViewDelegate
extension InboxViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        collectionView.cellForItem(at: indexPath)?.backgroundColor = .memoraFill
        memoryContextViewController.updates(from: viewModel.viewModelAt(index: indexPath))
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: { [unowned self] in self.memoryContextViewController },
                                          actionProvider: { (_) -> UIMenu? in
                                            let resetAction = UIAction(title: NSLocalizedString("reset-reminder",
                                                                                                comment: "Action to reset reminder"),
                                                                       image: UIImage(systemName: "arrow.clockwise")) { (_) in

                                            }
                                            let archiveAction = UIAction(title: NSLocalizedString("archive-memory",
                                                                                                  comment: "Action to archive memory"),
                                                                         image: UIImage(systemName: "archivebox")) { [weak self] (_) in
                                                self?.viewModel.archiveMemoryAt(index: indexPath)
                                            }
                                            let deleteAction = UIAction(title: NSLocalizedString("delete-memory",
                                                                                                 comment: "Action to delete memory."),
                                                                        image: UIImage(systemName: "trash"),
                                                                        attributes: .destructive) { (_) in

                                            }
                                            let children = [resetAction, archiveAction, deleteAction]
                                            return UIMenu(title: "", children: children)
                                          })
    }

}

// MARK: - UICollectionViewDataSource
extension InboxViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfMemories
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: InboxCollectionViewCell.identifier,
                                                         for: indexPath) as? InboxCollectionViewCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: viewModel.viewModelAt(index: indexPath))

        return cell
    }
}

// MARK: - ViewModel Delegate
extension InboxViewController: InboxViewModelDelegate {
    func deleteMemoryAt(_ index: IndexPath) {
        os_log("InboxViewController deleting memories...", log: .appFlow, type: .debug)
        inboxCollectionView.deleteItems(at: [index])
    }

    func updateMemoryAt(_ index: IndexPath) {
        if let cell = inboxCollectionView.cellForItem(at: index) as? InboxCollectionViewCell {
            os_log("InboxViewController updating memories...", log: .appFlow, type: .debug)
            let newViewModel = viewModel.viewModelAt(index: index)
            if newViewModel.isActive {
                cell.configure(with: newViewModel)
            } else {

                inboxCollectionView.deleteItems(at: [index])
            }
        }
    }

    func insertNewMemoryAt(_ index: IndexPath) {
        os_log("InboxViewController inserting new memories...", log: .appFlow, type: .debug)
        inboxCollectionView.insertItems(at: [index])
    }

    func updates(from blocks: [BlockOperation]) {
        os_log("InboxViewController peforming batch updates.", log: .appFlow, type: .debug)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            guard let self = self else { return }
            self.inboxCollectionView.performBatchUpdates({
                for block in blocks {
                    block.start()
                }
            }, completion: { [weak self] (didUpdate) in
                guard let self = self else {
                    return
                }
                self.viewModel.didUpdate = didUpdate
                os_log("InboxViewController done with batch updates.", log: .appFlow, type: .debug)
            })
        }
    }
}
