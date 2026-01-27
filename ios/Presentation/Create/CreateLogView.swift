import SwiftUI
import PhotosUI

struct CreateLogView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateLogViewModel
    @State private var showingPhotoSourceSheet = false
    @State private var showingCamera = false
    @State private var showingGallery = false
    @State private var hashtagInput = ""

    private let maxPhotos = 3

    init(recipe: RecipeSummary? = nil) {
        self._viewModel = StateObject(wrappedValue: CreateLogViewModel(recipe: recipe))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Recipe Link Section (moved to top)
                    recipeLinkSection
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.md)

                    Divider()

                    // Photo Section
                    photoSection
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.lg)

                    Divider()

                    // Rating Section
                    ratingSection
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.lg)

                    Divider()

                    // Description Section
                    descriptionSection
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.md)

                    Divider()

                    // Hashtags Section
                    hashtagsSection
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.md)

                    Divider()

                    // Privacy Toggle
                    privacySection
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.md)
                }
            }
            .background(DesignSystem.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: AppIcon.close)
                            .font(.system(size: DesignSystem.IconSize.md, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.text)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("New Cooking Log")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.text)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.submit()
                            if case .success = viewModel.state { dismiss() }
                        }
                    } label: {
                        Text("Post")
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(viewModel.canSubmit ? DesignSystem.Colors.primary : DesignSystem.Colors.tertiaryText)
                    }
                    .disabled(!viewModel.canSubmit)
                }
            }
            .alert("", isPresented: .constant(viewModel.state == .error(""))) {
                Button("OK") { }
            } message: {
                if case .error(let msg) = viewModel.state { Text(msg) }
            }
            .confirmationDialog("Add Photo", isPresented: $showingPhotoSourceSheet, titleVisibility: .visible) {
                Button("Take Photo") {
                    showingCamera = true
                }
                Button("Choose from Library") {
                    showingGallery = true
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showingCamera) {
                CameraPicker { image in
                    if let image = image {
                        viewModel.addPhoto(image)
                    }
                }
            }
            .sheet(isPresented: $showingGallery) {
                PhotosPickerSheet(maxSelection: maxPhotos - viewModel.photos.count) { images in
                    for image in images {
                        viewModel.addPhoto(image)
                    }
                }
            }
        }
    }

    // MARK: - Photo Section (3 Fixed Slots)
    private var photoSection: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(0..<maxPhotos, id: \.self) { index in
                photoSlot(at: index)
            }
        }
    }

    @ViewBuilder
    private func photoSlot(at index: Int) -> some View {
        let slotSize: CGFloat = (UIScreen.main.bounds.width - DesignSystem.Spacing.md * 2 - DesignSystem.Spacing.sm * 2) / 3

        if index < viewModel.photos.count {
            // Filled slot with image
            ZStack(alignment: .topTrailing) {
                Image(uiImage: viewModel.photos[index].image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: slotSize, height: slotSize)
                    .cornerRadius(DesignSystem.CornerRadius.sm)
                    .clipped()

                Button { viewModel.removePhoto(at: index) } label: {
                    Image(systemName: AppIcon.close)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .offset(x: -4, y: 4)
            }
            .frame(width: slotSize, height: slotSize)
        } else {
            // Empty slot
            Button {
                showingPhotoSourceSheet = true
            } label: {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: DesignSystem.IconSize.lg))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    Text("tap to add")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
                .frame(width: slotSize, height: slotSize)
                .background(DesignSystem.Colors.secondaryBackground)
                .cornerRadius(DesignSystem.CornerRadius.sm)
            }
        }
    }

    // MARK: - Rating Section
    private var ratingSection: some View {
        HStack {
            Spacer()
            InteractiveStarRating(rating: $viewModel.rating, size: DesignSystem.IconSize.xl)
            Spacer()
        }
    }

    // MARK: - Recipe Link Section
    private var recipeLinkSection: some View {
        NavigationLink(destination: RecipeSearchView(onSelect: { viewModel.selectRecipe($0) })) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: AppIcon.recipe)
                    .foregroundColor(DesignSystem.Colors.primary)

                if let recipe = viewModel.selectedRecipe {
                    AsyncImage(url: URL(string: recipe.coverImageUrl ?? "")) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            Image(systemName: "photo")
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        case .empty:
                            ProgressView()
                        @unknown default:
                            Rectangle().fill(DesignSystem.Colors.secondaryBackground)
                        }
                    }
                    .frame(width: 40, height: 40)
                    .background(DesignSystem.Colors.secondaryBackground)
                    .cornerRadius(DesignSystem.CornerRadius.xs)
                    .clipped()

                    Text(recipe.title)
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundColor(DesignSystem.Colors.text)
                        .lineLimit(1)
                    Spacer()
                    Button {
                        viewModel.selectRecipe(nil)
                    } label: {
                        Image(systemName: AppIcon.close)
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .frame(width: 24, height: 24)
                            .background(DesignSystem.Colors.secondaryBackground)
                            .clipShape(Circle())
                    }
                } else {
                    Text("Link a recipe")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Spacer()
                    Image(systemName: AppIcon.forward)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            TextEditor(text: $viewModel.content)
                .frame(minHeight: 100)
                .scrollContentBackground(.hidden)
                .onChange(of: viewModel.content) { _, newValue in
                    if newValue.count > viewModel.maxContentLength {
                        viewModel.content = String(newValue.prefix(viewModel.maxContentLength))
                    }
                }
                .overlay(alignment: .topLeading) {
                    if viewModel.content.isEmpty {
                        Text("Write about your cooking...")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                }

            HStack {
                Spacer()
                Text("\(viewModel.content.count)/\(viewModel.maxContentLength)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(viewModel.contentRemaining < 100 ? DesignSystem.Colors.error : DesignSystem.Colors.tertiaryText)
            }
        }
    }

    // MARK: - Hashtags Section
    private var hashtagsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Input row
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "number")
                    .foregroundColor(DesignSystem.Colors.primary)

                TextField("Add hashtag", text: $hashtagInput)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .submitLabel(.done)
                    .onSubmit {
                        addCurrentHashtag()
                    }

                if viewModel.hashtags.count < viewModel.maxHashtags {
                    Button {
                        addCurrentHashtag()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(hashtagInput.isEmpty ? DesignSystem.Colors.tertiaryText : DesignSystem.Colors.primary)
                    }
                    .disabled(hashtagInput.isEmpty)
                }

                Text("\(viewModel.hashtags.count)/\(viewModel.maxHashtags)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }

            // Hashtag chips
            if !viewModel.hashtags.isEmpty {
                FlowLayout(spacing: DesignSystem.Spacing.xs) {
                    ForEach(Array(viewModel.hashtags.enumerated()), id: \.element) { index, tag in
                        HStack(spacing: DesignSystem.Spacing.xxs) {
                            Text("#\(tag)")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundColor(DesignSystem.Colors.primary)

                            Button {
                                viewModel.removeHashtag(at: index)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(DesignSystem.Colors.primary.opacity(0.1))
                        .cornerRadius(DesignSystem.CornerRadius.full)
                    }
                }
            }
        }
    }

    private func addCurrentHashtag() {
        viewModel.addHashtag(hashtagInput)
        hashtagInput = ""
    }

    // MARK: - Privacy Section
    private var privacySection: some View {
        HStack {
            Image(systemName: viewModel.isPrivate ? "lock.fill" : "lock.open")
                .foregroundColor(DesignSystem.Colors.primary)
            Text(viewModel.isPrivate ? "Private" : "Public")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text)
            Spacer()
            Toggle("", isOn: $viewModel.isPrivate)
                .labelsHidden()
        }
    }
}

// MARK: - Camera Picker (UIImagePickerController wrapper)
struct CameraPicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImagePicked: (UIImage?) -> Void

        init(onImagePicked: @escaping (UIImage?) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            onImagePicked(image)
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onImagePicked(nil)
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Photos Picker Sheet (Multi-select gallery)
struct PhotosPickerSheet: UIViewControllerRepresentable {
    let maxSelection: Int
    let onImagesPicked: ([UIImage]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = maxSelection
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagesPicked: onImagesPicked)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onImagesPicked: ([UIImage]) -> Void

        init(onImagesPicked: @escaping ([UIImage]) -> Void) {
            self.onImagesPicked = onImagesPicked
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            var images: [UIImage] = []
            let group = DispatchGroup()

            for result in results {
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                    if let image = object as? UIImage {
                        images.append(image)
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) { [weak self] in
                self?.onImagesPicked(images)
            }
        }
    }
}

// MARK: - Recipe Search View
struct RecipeSearchView: View {
    let onSelect: (RecipeSummary) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = RecipeSearchViewModel()
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Search bar at top
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                TextField("Search recipes...", text: $viewModel.query)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        Task { await viewModel.search() }
                    }
                if !viewModel.query.isEmpty {
                    Button {
                        viewModel.query = ""
                        viewModel.searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                }
            }
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.secondaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.sm)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.top, DesignSystem.Spacing.sm)

            // Content
            List {
                if viewModel.query.isEmpty {
                    // Show recent recipes when not searching
                    if viewModel.isLoadingRecent {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    } else if !viewModel.recentRecipes.isEmpty {
                        Section {
                            ForEach(viewModel.recentRecipes) { recipe in
                                recipeRow(recipe)
                            }
                        } header: {
                            Text("Recently Viewed")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    } else {
                        ContentUnavailableView(
                            "No Recent Recipes",
                            systemImage: "clock",
                            description: Text("Recipes you've viewed will appear here")
                        )
                    }
                } else {
                    // Show search results
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    } else if viewModel.searchResults.isEmpty && !viewModel.query.isEmpty {
                        ContentUnavailableView.search(text: viewModel.query)
                    } else {
                        ForEach(viewModel.searchResults) { recipe in
                            recipeRow(recipe)
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Search Recipes")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.query) { _, newValue in
            if !newValue.isEmpty {
                Task { await viewModel.search() }
            }
        }
        .task {
            await viewModel.loadRecentRecipes()
        }
    }

    private func recipeRow(_ recipe: RecipeSummary) -> some View {
        Button {
            onSelect(recipe)
            dismiss()
        } label: {
            HStack(spacing: DesignSystem.Spacing.sm) {
                AsyncImage(url: URL(string: recipe.coverImageUrl ?? "")) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(DesignSystem.Colors.secondaryBackground)
                }
                .frame(width: 50, height: 50)
                .cornerRadius(DesignSystem.CornerRadius.xs)
                .clipped()

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text(recipe.title)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text)
                        .lineLimit(1)
                    Text(recipe.userName)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recipe Search ViewModel
@MainActor
final class RecipeSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var searchResults: [RecipeSummary] = []
    @Published var recentRecipes: [RecipeSummary] = []
    @Published var isLoading = false
    @Published var isLoadingRecent = false

    private let recipeRepository: RecipeRepositoryProtocol
    private let maxRecentRecipes = 5

    init(recipeRepository: RecipeRepositoryProtocol = RecipeRepository()) {
        self.recipeRepository = recipeRepository
    }

    func search() async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }

        isLoading = true
        let filters = RecipeFilters(searchQuery: query)
        let result = await recipeRepository.getRecipes(cursor: nil, filters: filters)

        switch result {
        case .success(let response):
            searchResults = response.content
        case .failure:
            searchResults = []
        }
        isLoading = false
    }

    func loadRecentRecipes() async {
        isLoadingRecent = true
        let result = await recipeRepository.getRecentlyViewedRecipes(limit: maxRecentRecipes)
        switch result {
        case .success(let recipes):
            recentRecipes = recipes
        case .failure:
            recentRecipes = []
        }
        isLoadingRecent = false
    }
}

#Preview { CreateLogView() }
