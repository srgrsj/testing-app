import SwiftUI

struct DishesListView: View {
    @StateObject var viewModel: DishesListViewModel

    @State private var isPresentingCreate = false
    @State private var isPresentingFilters = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.dishes.isEmpty {
                    ProgressView("Загружаем блюда")
                } else if let error = viewModel.errorMessage, viewModel.dishes.isEmpty {
                    ContentUnavailableView("Ошибка", systemImage: "exclamationmark.triangle", description: Text(error))
                } else if viewModel.dishes.isEmpty {
                    ContentUnavailableView("Пусто", systemImage: "fork.knife", description: Text("Добавьте первое блюдо"))
                } else {
                    List {
                        ForEach(viewModel.dishes) { dish in
                            NavigationLink {
                                DishDetailView(
                                    viewModel: DishDetailViewModel(dishId: dish.id, useCases: viewModel.useCases),
                                    makeEditorViewModel: { DishEditorViewModel(editingDish: $0, useCases: viewModel.useCases) },
                                    onChanged: { await viewModel.load() }
                                )
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    RemoteThumbnailView(urlString: dish.photos.first, size: 64)

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(dish.name)
                                            .font(.headline)
                                        HStack {
                                            Text(dish.category.title)
                                            Text("•")
                                            Text("\(dish.ingredients.count) ингредиентов")
                                        }
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                        Text("К: \(dish.calories, specifier: "%.0f") Б: \(dish.proteins, specifier: "%.1f") Ж: \(dish.fats, specifier: "%.1f") У: \(dish.carbs, specifier: "%.1f")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { await viewModel.deleteDish(id: dish.id) }
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Блюда")
            .searchable(text: $viewModel.searchText, prompt: "Поиск по названию")
            .onSubmit(of: .search) {
                Task { await viewModel.load() }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        isPresentingFilters = true
                    } label: {
                        Label("Фильтры", systemImage: "slider.horizontal.3")
                    }

                    Button {
                        isPresentingCreate = true
                    } label: {
                        Label("Создать", systemImage: "plus")
                    }
                }
            }
            .task {
                if viewModel.dishes.isEmpty {
                    await viewModel.load()
                }
            }
            .refreshable {
                await viewModel.load()
            }
        }
        .sheet(isPresented: $isPresentingCreate) {
            DishEditorView(
                viewModel: DishEditorViewModel(editingDish: nil, useCases: viewModel.useCases),
                onSaved: { await viewModel.load() }
            )
        }
        .sheet(isPresented: $isPresentingFilters) {
            DishFiltersSheet(filters: $viewModel.filters) {
                Task { await viewModel.load() }
            }
        }
        .alert("Ошибка", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

private struct DishFiltersSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filters: DishListFilters
    let onApply: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Категория") {
                    Picker("Категория", selection: $filters.category) {
                        Text("Любая").tag(DishCategory?.none)
                        ForEach(DishCategory.allCases) { value in
                            Text(value.title).tag(DishCategory?.some(value))
                        }
                    }
                }

                Section("Флаги") {
                    ForEach(FeatureFlag.allCases) { flag in
                        Toggle(isOn: Binding(
                            get: { filters.flags.contains(flag) },
                            set: { isOn in
                                if isOn {
                                    filters.flags.insert(flag)
                                } else {
                                    filters.flags.remove(flag)
                                }
                            }
                        )) {
                            Text(flag.title)
                        }
                    }
                }
            }
            .navigationTitle("Фильтры")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Сброс") {
                        filters = DishListFilters()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Применить") {
                        onApply()
                        dismiss()
                    }
                }
            }
        }
    }
}
