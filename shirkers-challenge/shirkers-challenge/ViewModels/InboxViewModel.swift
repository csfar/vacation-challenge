//
//  InboxViewModel.swift
//  shirkers-challenge
//
//  Created by Artur Carneiro on 16/10/20.
//  Copyright © 2020 Artur Carneiro. All rights reserved.
//

import CoreData
import UserNotifications
import os.log

// MARK: - Protocol-Delegate
/// The delegate responsible for allowing communication between
/// `InboxViewModelDelegate` and its `View`.
protocol InboxViewModelDelegate: AnyObject {
    func insertNewMemoryAt(_ index: IndexPath)
    func deleteMemoryAt(_ index: IndexPath)
    func updateMemoryAt(_ index: IndexPath)
    func updates(from blocks: [BlockOperation])
}

/// Responsible for providing the `View` with all the necessary
/// funcionalities and data for displaying the inbox.
final class InboxViewModel: NSObject {
    // MARK: - Properties
    /// The context used to access Core Data through a FRC.
    private let context: NSManagedObjectContext

    /// The update blocks used to batch update the `View`.
    private var updateBlock: [BlockOperation] = [BlockOperation]()

    /// The FRC responsible for fetching memories. It orders memories
    /// by last modified. Returns only active memories which the due date is equal or
    /// lower than `Date()` .
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

    /// The delegate responsible for allowing communication between
    /// `InboxViewModel` and its `View`.
    weak var delegate: InboxViewModelDelegate?

    /// The `UNUserNotificationCenter` instance responsible for scheduling notifications.
    private let uncenter: UNUserNotificationCenter

    // MARK: - Init
    /// Initializes a new instance of this type.
    /// - Parameter context: The context used to access Core Data through a FRC.
    init(context: NSManagedObjectContext,
         uncenter: UNUserNotificationCenter = UNUserNotificationCenter.current()) {
        self.context = context
        self.uncenter = uncenter
        os_log("InboxViewModel initialized.", log: .appFlow, type: .debug)
    }

    // MARK: - API
    /// The number of memories fetched by the FRC.
    var numberOfMemories: Int {
        guard let memories = fetchedResultsController.fetchedObjects else {
            return 0
        }
        return memories.count
    }

    /// Whether the `View` has been updated.
    var didUpdate: Bool = false {
        didSet {
            if didUpdate {
                updateBlock.removeAll(keepingCapacity: false)
            }
        }
    }

    /// Requests a fetch from the FRC.
    func requestFetch() {
        do {
            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "dueDate =< %@ AND isActive == true", Date() as NSDate)
            try fetchedResultsController.performFetch()
        } catch {
            os_log("InboxViewModel fetch request to FRC failed.", log: .appFlow, type: .error)
        }
    }

    /// Returns a `ViewModel` corresponding to an index.
    func viewModelAt(index: IndexPath) -> MemoryViewModel {
        let memory = fetchedResultsController.object(at: index)

        guard let title = memory.title,
                   let createdAt = memory.createdAt,
                   let modifiedAt = memory.modifiedAt,
                   let dueDate = memory.dueDate else {
                    return MemoryViewModel()
                   }

        return MemoryViewModel(title: title,
                               createdAt: createdAt,
                               isActive: memory.isActive,
                               modifiedAt: modifiedAt,
                               dueDate: dueDate)
    }

    /// Deletes a memory.
    /// - Parameter index: `IndexPath` corresponding to the memory.
    func deleteMemoryAt(index: IndexPath) {
        os_log("ArchiveViewController deleting memory...", log: .appFlow, type: .debug)
        let memory = fetchedResultsController.object(at: index)

        guard let createdAt = memory.createdAt else {
            return
        }
        remove(file: createdAt.toBeSavedFormat())
        context.delete(memory)
    }

    func archiveMemoryAt(index: IndexPath) {
        os_log("InboxViewController archiving memory...", log: .appFlow, type: .debug)
        let memory = fetchedResultsController.object(at: index)

        memory.isActive = false
    }

    /// Resets the due date of a memory.
    /// - Parameter index: `IndexPath` corresponding to the memory.
    func resetMemoryAt(index: IndexPath) {
        let memory = fetchedResultsController.object(at: index)

        guard let dueDate = memory.dueDate,
              let modifiedAt = memory.modifiedAt else {
            os_log("InboxViewModel failed to retrieve a valid memory", log: .appFlow, type: .error)
            return
        }

        let newDueDateInterval = dueDate.timeIntervalSince(modifiedAt)
        schedule(for: newDueDateInterval, with: modifiedAt.toBeSavedFormat())

        let newModifiedAtDate = Date()
        memory.dueDate = Date(timeInterval: newDueDateInterval, since: newModifiedAtDate)
        memory.modifiedAt = newModifiedAtDate

        if context.hasChanges {
            do {
                try context.save()
                os_log("InboxViewModel has saved to save to Core Data.", log: .appFlow, type: .debug)
            } catch {
                os_log("InboxViewModel has failed to save to Core Data.", log: .appFlow, type: .error)
            }
        }
    }

    // MARK: - UserNotification
    private func schedule(for interval: TimeInterval, with identifier: String) {
        uncenter.getNotificationSettings { [weak self] (settings) in
            guard let self = self else {
                return
            }

            switch settings.authorizationStatus {
            case .authorized:
                os_log("InboxViewModel is scheduling a notification...", log: .appFlow, type: .debug)
                let content = UNMutableNotificationContent()
                content.title = NSLocalizedString("notification-title", comment: "")
                content.body = NSLocalizedString("notification-body", comment: "")
                content.sound = .default

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)

                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                self.uncenter.add(request) { (error) in
                    if error != nil {
                        os_log("InboxViewModel failed to schedule notification.", log: .appFlow, type: .error)
                    } else {
                        os_log("InboxViewModel successfully scheduled a notification.", log: .appFlow, type: .debug)
                    }
                }
            case .denied:
                os_log("InboxViewModel can`t schedule notification due to `denied` authorization status.", log: .appFlow, type: .debug)
            default:
                os_log("InboxViewModel has unknown user notification status.", log: .appFlow, type: .debug)
            }
        }
    }

    // MARK: - FileManager
    /// Removes file representing a memory's audio.
    private func remove(file: String, at fileManager: FileManager = FileManager.default) {
        let url = fileManager.userDocumentDirectory
        let fileURL = url.appendingPathComponent("\(file)").appendingPathExtension("m4a")
        do {
            os_log("InboxViewModel removed memory's file.", log: .appFlow, type: .debug)
            try fileManager.removeItem(at: fileURL)
        } catch {
            os_log("InboxViewModel failed to remove a memory's file.", log: .appFlow, type: .error)
        }
    }
}

// MARK: - FRC Delegate
extension InboxViewModel: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        os_log("InboxViewModel data updating...", log: .appFlow, type: .debug)
        updateBlock.removeAll(keepingCapacity: false)
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        let block = BlockOperation { [weak self] in
            guard let self = self else { return }
            switch type {
            case .insert:
                if let newIndexPath = newIndexPath {
                    os_log("InboxViewModel inserted new memory.", log: .appFlow, type: .debug)
                    self.delegate?.insertNewMemoryAt(newIndexPath)
                }
            case .delete:
                if let indexPath = indexPath {
                    os_log("InboxViewModel deleted memory.", log: .appFlow, type: .debug)
                    self.delegate?.deleteMemoryAt(indexPath)
                }
            case .update:
                if let indexPath = indexPath {
                    os_log("InboxViewModel updated memory.", log: .appFlow, type: .debug)
                    self.delegate?.updateMemoryAt(indexPath)
                }
            default:
                break
            }
        }
        updateBlock.append(block)
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        os_log("InboxViewModel is done updating. Sending update blocks to View.", log: .appFlow, type: .debug)
        if context.hasChanges {
            do {
                try context.save()
                os_log("InboxViewModel has saved to save to Core Data.", log: .appFlow, type: .debug)
            } catch {
                os_log("InboxViewModel has failed to save to Core Data.", log: .appFlow, type: .error)
            }
        }
        delegate?.updates(from: updateBlock)
    }
}
