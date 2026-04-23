import SwiftUI

struct ProductDetailView: View {
    @StateObject var viewModel: ProductDetailViewModel
    let makeEditorViewModel: (Product?) -> ProductEditorViewModel
    let onChanged: () async -> Void

    @State private var isEditing = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Загрузка продукта")
            } else if let product = viewModel.product {
                List {
                    if !product.photos.isEmpty {
                        Section("Фотографии") {
                            RemoteGalleryView(photos: product.photos, itemWidth: 180, itemHeight: 120)
                        }
                    }

                    Section("Описание") {
                        LabeledContent("Название", value: product.name)
                        LabeledContent("Категория", value: product.category.title)
                        LabeledContent("Подготовка", value: product.preparation.title)
                        if let composition = product.composition {
                            LabeledContent("Состав", value: composition)
                        }
                    }

                    Section("Пищевая ценность") {
                        LabeledContent("Калории", value: String(format: "%.1f", product.calories))
                        LabeledContent("Белки", value: String(format: "%.1f", product.proteins))
                        LabeledContent("Жиры", value: String(format: "%.1f", product.fats))
                        LabeledContent("Углеводы", value: String(format: "%.1f", product.carbs))
                    }

                    Section("Флаги") {
                        if product.flags.isEmpty {
                            Text("Нет")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(product.flags.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { flag in
                                Text(flag.title)
                            }
                        }
                    }

                    Section("Системное") {
                        LabeledContent("Создан", value: DateParsing.humanReadable(product.createdAt))
                        if let updatedAt = product.updatedAt {
                            LabeledContent("Обновлен", value: DateParsing.humanReadable(updatedAt))
                        }
                    }
                }
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView("Ошибка", systemImage: "exclamationmark.triangle", description: Text(error))
            } else {
                ContentUnavailableView("Продукт не найден", systemImage: "shippingbox")
            }
        }
        .navigationTitle("Карточка")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if viewModel.product != nil {
                    Button("Изменить") {
                        isEditing = true
                    }
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .sheet(isPresented: $isEditing) {
            ProductEditorView(
                viewModel: makeEditorViewModel(viewModel.product),
                onSaved: {
                    await viewModel.load()
                    await onChanged()
                }
            )
        }
    }
}
