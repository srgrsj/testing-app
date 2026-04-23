import SwiftUI

struct DishDetailView: View {
    @StateObject var viewModel: DishDetailViewModel
    let makeEditorViewModel: (Dish?) -> DishEditorViewModel
    let onChanged: () async -> Void

    @State private var isEditing = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Загрузка блюда")
            } else if let dish = viewModel.dish {
                List {
                    if !dish.photos.isEmpty {
                        Section("Фотографии") {
                            RemoteGalleryView(photos: dish.photos, itemWidth: 180, itemHeight: 120)
                        }
                    }

                    Section("Описание") {
                        LabeledContent("Название", value: dish.name)
                        LabeledContent("Категория", value: dish.category.title)
                        LabeledContent("Порция", value: String(format: "%.1f г", dish.portionSize))
                    }

                    Section("Пищевая ценность") {
                        LabeledContent("Калории", value: String(format: "%.1f", dish.calories))
                        LabeledContent("Белки", value: String(format: "%.1f", dish.proteins))
                        LabeledContent("Жиры", value: String(format: "%.1f", dish.fats))
                        LabeledContent("Углеводы", value: String(format: "%.1f", dish.carbs))
                    }

                    Section("Ингредиенты") {
                        ForEach(dish.ingredients) { ingredient in
                            HStack {
                                Text(ingredient.productName)
                                Spacer()
                                Text("\(ingredient.quantity, specifier: "%.1f") г")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Section("Флаги") {
                        if dish.flags.isEmpty {
                            Text("Нет")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(dish.flags.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { flag in
                                Text(flag.title)
                            }
                        }
                    }

                    Section("Системное") {
                        LabeledContent("Создано", value: DateParsing.humanReadable(dish.createdAt))
                        if let updatedAt = dish.updatedAt {
                            LabeledContent("Обновлено", value: DateParsing.humanReadable(updatedAt))
                        }
                    }
                }
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView("Ошибка", systemImage: "exclamationmark.triangle", description: Text(error))
            } else {
                ContentUnavailableView("Блюдо не найдено", systemImage: "fork.knife")
            }
        }
        .navigationTitle("Карточка")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if viewModel.dish != nil {
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
            DishEditorView(
                viewModel: makeEditorViewModel(viewModel.dish),
                onSaved: {
                    await viewModel.load()
                    await onChanged()
                }
            )
        }
    }
}
