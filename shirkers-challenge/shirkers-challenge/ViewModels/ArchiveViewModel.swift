//
//  ArchiveViewModel.swift
//  shirkers-challenge
//
//  Created by Artur Carneiro on 13/10/20.
//  Copyright © 2020 Artur Carneiro. All rights reserved.
//

import CoreData

// MARK: - Protocol-Delegate
protocol ArchiveViewModelDelegate: AnyObject {
    func beginUpdates()
    func insertNewMemoryAt(_ index: IndexPath)
    func deleteMemoryAt(_ index: IndexPath)
    func endUpdates()
}

final class ArchiveViewModel: NSObject {
    // MARK: - Properties
    private let context: NSManagedObjectContext

    private lazy var fetchedResultsController: NSFetchedResultsController<Recording> = {
        let fetchRequest: NSFetchRequest<Recording> = Recording.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Recording.modifiedAt, ascending: false)]

        let frc = NSFetchedResultsController(fetchRequest: fetchRequest,
                                             managedObjectContext: self.context,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        frc.delegate = self

        return frc
    }()

    weak var delegate: ArchiveViewModelDelegate?

    // MARK: - Init
    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - API
    var numberOfMemories: Int {
        guard let memories = fetchedResultsController.fetchedObjects else {
            return 0
        }
        return memories.count
    }

    func requestFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print(error.localizedDescription)
            // TODO: Error handling
        }
    }

    func viewModelAt(index: IndexPath) -> ArchiveTableViewCellViewModel {
        let memory = fetchedResultsController.object(at: index)

        guard let title = memory.title,
              let createdAt = memory.createdAt?.stringFormatted(),
              let modifiedAt = memory.modifiedAt?.stringFormatted(),
              let period = memory.dueDate?.stringFormatted() else {
            return ArchiveTableViewCellViewModel()
        }

        return ArchiveTableViewCellViewModel(title: title,
                                             createdAt: createdAt,
                                             isActive: memory.isActive,
                                             modifiedAt: modifiedAt,
                                             period: period)
    }

}

// MARK: - FRC Delegate
extension ArchiveViewModel: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.beginUpdates()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.endUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                delegate?.insertNewMemoryAt(newIndexPath)
            }
        case .delete:
            if let newIndexPath = newIndexPath {
                delegate?.deleteMemoryAt(newIndexPath)
            }
        default:
            break
        }
    }
}