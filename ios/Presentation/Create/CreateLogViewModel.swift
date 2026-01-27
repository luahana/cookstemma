import Foundation
import SwiftUI

enum CreateLogState: Equatable {
    case idle, uploading, submitting, success(CookingLogDetail), error(String)
}

struct SelectedPhoto: Identifiable, Equatable {
    let id: String
    let image: UIImage
    var uploadedId: String?
}

@MainActor
final class CreateLogViewModel: ObservableObject {
    @Published private(set) var state: CreateLogState = .idle
    @Published var photos: [SelectedPhoto] = []
    @Published var rating: Int = 0
    @Published var content: String = ""
    @Published var selectedRecipe: RecipeSummary?
    @Published var hashtags: [String] = []
    @Published var isPrivate: Bool = false

    private let logRepository: CookingLogRepositoryProtocol
    private let maxPhotos = 5

    var canSubmit: Bool { !photos.isEmpty && rating >= 1 && state != .uploading && state != .submitting }
    var photosRemaining: Int { max(0, maxPhotos - photos.count) }

    init(logRepository: CookingLogRepositoryProtocol = CookingLogRepository()) {
        self.logRepository = logRepository
    }

    func addPhoto(_ image: UIImage) {
        guard photos.count < maxPhotos else { return }
        photos.append(SelectedPhoto(id: UUID().uuidString, image: image))
    }

    func removePhoto(at index: Int) {
        guard photos.indices.contains(index) else { return }
        photos.remove(at: index)
    }

    func selectRecipe(_ recipe: RecipeSummary?) { selectedRecipe = recipe }

    func submit() async {
        guard canSubmit else { return }
        state = .uploading
        let imageIds = photos.compactMap { $0.uploadedId ?? $0.id }
        state = .submitting

        let request = CreateLogRequest(rating: rating, content: content.isEmpty ? nil : content, imageIds: imageIds,
            recipeId: selectedRecipe?.id, hashtags: hashtags, isPrivate: isPrivate)
        let result = await logRepository.createLog(request)

        switch result {
        case .success(let log): state = .success(log)
        case .failure(let error): state = .error(error.localizedDescription)
        }
    }

    func reset() {
        state = .idle; photos = []; rating = 0; content = ""; selectedRecipe = nil; hashtags = []; isPrivate = false
    }
}
