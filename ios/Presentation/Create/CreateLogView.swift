import SwiftUI
import PhotosUI

struct CreateLogView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateLogViewModel()
    @State private var selectedItems: [PhotosPickerItem] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Photo Section
                    photoSection

                    // Rating Section
                    ratingSection

                    // Recipe Link Section
                    recipeLinkSection

                    // Description Section
                    descriptionSection

                    // Privacy Toggle
                    privacySection
                }
                .padding(DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.secondaryBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CloseButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    postButton
                }
            }
            .alert("", isPresented: .constant(viewModel.state == .error(""))) {
                Button("OK") { }
            } message: {
                if case .error(let msg) = viewModel.state { Text(msg) }
            }
        }
    }

    // MARK: - Photo Section (Icon-focused)
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: AppIcon.photo)
                    .foregroundColor(DesignSystem.Colors.primary)
                Spacer()
                Text("\(viewModel.photos.count)/5")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }

            if viewModel.photos.isEmpty {
                PhotosPicker(selection: $selectedItems, maxSelectionCount: 5, matching: .images) {
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: AppIcon.addPhoto)
                            .font(.system(size: DesignSystem.IconSize.xxl))
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                        Text("+")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(DesignSystem.Colors.background)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    )
                }
                .onChange(of: selectedItems) { _, newItems in
                    Task { await loadPhotos(from: newItems) }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        ForEach(Array(viewModel.photos.enumerated()), id: \.element.id) { index, photo in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: photo.image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(DesignSystem.CornerRadius.sm)
                                    .clipped()
                                Button { viewModel.removePhoto(at: index) } label: {
                                    Image(systemName: AppIcon.close)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .offset(x: 4, y: -4)
                            }
                        }

                        // Add more button
                        if viewModel.photosRemaining > 0 {
                            PhotosPicker(selection: $selectedItems, maxSelectionCount: viewModel.photosRemaining, matching: .images) {
                                VStack {
                                    Image(systemName: "plus")
                                        .font(.system(size: DesignSystem.IconSize.lg))
                                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                                }
                                .frame(width: 100, height: 100)
                                .background(DesignSystem.Colors.background)
                                .cornerRadius(DesignSystem.CornerRadius.sm)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                        .stroke(DesignSystem.Colors.tertiaryText, lineWidth: 1)
                                )
                            }
                            .onChange(of: selectedItems) { _, newItems in
                                Task { await loadPhotos(from: newItems) }
                            }
                        }
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }

    // MARK: - Rating Section (Icon-focused)
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Image(systemName: AppIcon.star)
                .foregroundColor(DesignSystem.Colors.primary)

            HStack {
                Spacer()
                InteractiveStarRating(rating: $viewModel.rating, size: DesignSystem.IconSize.xl)
                Spacer()
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }

    // MARK: - Recipe Link Section (Icon-focused)
    private var recipeLinkSection: some View {
        NavigationLink(destination: RecipeSearchView(onSelect: { viewModel.selectRecipe($0) })) {
            HStack {
                Image(systemName: AppIcon.recipe)
                    .foregroundColor(DesignSystem.Colors.primary)

                if let recipe = viewModel.selectedRecipe {
                    if let url = recipe.coverImageUrl {
                        AsyncImage(url: URL(string: url)) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            Rectangle().fill(DesignSystem.Colors.secondaryBackground)
                        }
                        .frame(width: 40, height: 40)
                        .cornerRadius(DesignSystem.CornerRadius.xs)
                        .clipped()
                    }
                    Text(recipe.title)
                        .font(DesignSystem.Typography.subheadline)
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
                    Spacer()
                    Image(systemName: AppIcon.forward)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.background)
            .cornerRadius(DesignSystem.CornerRadius.md)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Image(systemName: AppIcon.edit)
                .foregroundColor(DesignSystem.Colors.primary)

            TextEditor(text: $viewModel.content)
                .frame(minHeight: 100)
                .scrollContentBackground(.hidden)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }

    // MARK: - Privacy Section (Icon-focused)
    private var privacySection: some View {
        HStack {
            Image(systemName: viewModel.isPrivate ? "lock.fill" : "lock.open")
                .foregroundColor(DesignSystem.Colors.primary)
            Spacer()
            Toggle("", isOn: $viewModel.isPrivate)
                .labelsHidden()
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }

    // MARK: - Post Button (Icon)
    private var postButton: some View {
        Button {
            Task {
                await viewModel.submit()
                if case .success = viewModel.state { dismiss() }
            }
        } label: {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: DesignSystem.IconSize.lg))
                .foregroundColor(viewModel.canSubmit ? DesignSystem.Colors.primary : DesignSystem.Colors.tertiaryText)
        }
        .disabled(!viewModel.canSubmit)
    }

    private func loadPhotos(from items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                viewModel.addPhoto(image)
            }
        }
        selectedItems = []
    }
}

// MARK: - Recipe Search View
struct RecipeSearchView: View {
    let onSelect: (RecipeSummary) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [RecipeSummary] = []

    var body: some View {
        List {
            ForEach(results) { recipe in
                Button {
                    onSelect(recipe)
                    dismiss()
                } label: {
                    HStack {
                        AsyncImage(url: URL(string: recipe.coverImageUrl ?? "")) { img in img.resizable().scaledToFill() }
                            placeholder: { Rectangle().fill(DesignSystem.Colors.secondaryBackground) }
                            .frame(width: 50, height: 50).cornerRadius(DesignSystem.CornerRadius.xs).clipped()
                        Text(recipe.title)
                    }
                }
            }
        }
        .searchable(text: $query)
        .navigationTitle("Search Recipes")
    }
}

#Preview { CreateLogView() }
