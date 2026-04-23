import SwiftUI

struct ProductEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: ProductEditorViewModel
    let onSaved: () async -> Void

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
                    Text("По одному URL на строку")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $viewModel.photosText)
                        .frame(minHeight: 120)
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
        }
    }
}
