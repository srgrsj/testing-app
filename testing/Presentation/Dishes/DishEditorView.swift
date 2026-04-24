import SwiftUI
import PhotosUI

struct DishEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: DishEditorViewModel
    let onSaved: () async -> Void
    @State private var showingAddPhotoOptions = false
    @State private var showingGalleryPicker = false
    @State private var pickedPhotoItems: [PhotosPickerItem] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    TextField("Название", text: $viewModel.name)
                    Text("Подсказка: используйте !десерт, !первое, !второе, !напиток, !салат, !суп, !перекус для автоматического определения категории")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Категория", selection: viewModel.categoryBinding) {
                        ForEach(DishCategory.allCases) { category in
                            Text(category.title).tag(category)
                        }
                    }
                    TextField("Размер порции", text: $viewModel.portionSizeText)
                        .keyboardType(.decimalPad)
                }

                Section("Ингредиенты") {
                    if viewModel.products.isEmpty {
                        Text("Сначала создайте продукты")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach($viewModel.ingredients) { $ingredient in
                            VStack(alignment: .leading) {
                                Picker("Продукт", selection: $ingredient.productId) {
                                    ForEach(viewModel.products) { product in
                                        Text(product.name).tag(product.id)
                                    }
                                }
                                .onChange(of: ingredient.productId) { _, _ in
                                    viewModel.syncDerivedStateForCompositionChange()
                                }

                                HStack {
                                    TextField("Количество (г)", value: $ingredient.quantity, format: .number)
                                        .keyboardType(.decimalPad)
                                        .onChange(of: ingredient.quantity) { _, _ in
                                            viewModel.syncDerivedStateForCompositionChange()
                                        }
                                    Stepper("", value: $ingredient.quantity, in: 1 ... 5000, step: 10)
                                        .labelsHidden()
                                }
                            }
                        }
                        .onDelete { offsets in
                            viewModel.ingredients.remove(atOffsets: offsets)
                            viewModel.syncDerivedStateForCompositionChange()
                        }

                        Button {
                            viewModel.addIngredient()
                        } label: {
                            Label("Добавить ингредиент", systemImage: "plus")
                        }
                    }
                }

                Section("БЖУ") {
                    TextField("Калории", text: $viewModel.caloriesText)
                        .keyboardType(.decimalPad)
                        .onChange(of: viewModel.caloriesText) { _, _ in
                            viewModel.markNutritionFieldEdited(.calories)
                        }
                    TextField("Белки", text: $viewModel.proteinsText)
                        .keyboardType(.decimalPad)
                        .onChange(of: viewModel.proteinsText) { _, _ in
                            viewModel.markNutritionFieldEdited(.proteins)
                        }
                    TextField("Жиры", text: $viewModel.fatsText)
                        .keyboardType(.decimalPad)
                        .onChange(of: viewModel.fatsText) { _, _ in
                            viewModel.markNutritionFieldEdited(.fats)
                        }
                    TextField("Углеводы", text: $viewModel.carbsText)
                        .keyboardType(.decimalPad)
                        .onChange(of: viewModel.carbsText) { _, _ in
                            viewModel.markNutritionFieldEdited(.carbs)
                        }

                    Button("Пересчитать автоматически") {
                        viewModel.recalculateNutritionDraft(forceOverride: true)
                    }
                }

                Section("Флаги") {
                    ForEach(FeatureFlag.allCases) { flag in
                        Toggle(isOn: Binding(
                            get: { viewModel.selectedFlags.contains(flag) },
                            set: { _ in viewModel.toggleFlag(flag) }
                        )) {
                            Text(flag.title)
                        }
                        .disabled(!viewModel.availableFlags.contains(flag))
                    }

                    if viewModel.availableFlags.count < FeatureFlag.allCases.count {
                        Text("Флаг доступен только если все продукты в составе имеют этот же флаг")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
            .task {
                if viewModel.products.isEmpty {
                    await viewModel.loadProducts()
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
        }
    }
}
