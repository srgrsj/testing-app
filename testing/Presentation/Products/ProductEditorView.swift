import SwiftUI
import PhotosUI

struct ProductEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: ProductEditorViewModel
    let onSaved: () async -> Void
    @State private var showingAddPhotoOptions = false
    @State private var showingGalleryPicker = false
    @State private var pickedPhotoItems: [PhotosPickerItem] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    TextField("Название", text: $viewModel.name)
                    Picker("Категория", selection: $viewModel.category) {
                        ForEach(ProductCategory.allCases) { category in
                            Text(category.title).tag(category)
                        }
                    }
                    Picker("Подготовка", selection: $viewModel.preparation) {
                        ForEach(PreparationStatus.allCases) { status in
                            Text(status.title).tag(status)
                        }
                    }
                    TextField("Состав", text: $viewModel.composition, axis: .vertical)
                        .lineLimit(3 ... 8)
                }

                Section("БЖУ") {
                    TextField("Калории", text: $viewModel.caloriesText)
                        .keyboardType(.decimalPad)
                    TextField("Белки", text: $viewModel.proteinsText)
                        .keyboardType(.decimalPad)
                    TextField("Жиры", text: $viewModel.fatsText)
                        .keyboardType(.decimalPad)
                    TextField("Углеводы", text: $viewModel.carbsText)
                        .keyboardType(.decimalPad)
                }

                Section("Флаги") {
                    ForEach(FeatureFlag.allCases) { flag in
                        Toggle(isOn: Binding(
                            get: { viewModel.selectedFlags.contains(flag) },
                            set: { _ in viewModel.toggleFlag(flag) }
                        )) {
                            Text(flag.title)
                        }
                    }
                }

                Section("Фото") {
                    ForEach(Array(viewModel.photos.enumerated()), id: \.offset) { index, photo in
                        HStack {
                            RemoteThumbnailView(urlString: photo, size: 60)
                                .frame(width: 60, height: 60)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(photo)
                                    .font(.caption)
                                    .lineLimit(2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(action: { viewModel.removePhoto(at: index) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    
                    Button(action: { showingAddPhotoOptions = true }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Добавить")
                        }
                    }
                    .confirmationDialog("Добавить фото", isPresented: $showingAddPhotoOptions, titleVisibility: .visible) {
                        Button("Ссылка") { viewModel.showingPhotoURLInput = true }
                        Button("Галерея") { showingGalleryPicker = true }
                        Button("Отмена", role: .cancel) {}
                    }
                    .alert("Добавить фотографию", isPresented: $viewModel.showingPhotoURLInput) {
                        TextField("URL фотографии", text: $viewModel.photoURLInput)
                        Button("Отмена", role: .cancel) { }
                        Button("Добавить") { viewModel.addPhotoFromURL(viewModel.photoURLInput) }
                    }
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .photosPicker(isPresented: $showingGalleryPicker, selection: $pickedPhotoItems, maxSelectionCount: 10, matching: .images)
            .onChange(of: pickedPhotoItems) { _, newItems in
                guard !newItems.isEmpty else { return }
                Task {
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            let base64 = data.base64EncodedString()
                            let mimeType = item.supportedContentTypes.first?.preferredMIMEType ?? "image/jpeg"
                            viewModel.addPhotoDataURL("data:\(mimeType);base64,\(base64)")
                        }
                    }
                    pickedPhotoItems.removeAll()
                }
            }
            .navigationTitle(viewModel.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        Task {
                            let saved = await viewModel.save()
                            if saved {
                                await onSaved()
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
