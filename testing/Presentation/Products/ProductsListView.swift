import SwiftUI

struct ProductsListView: View {
    @StateObject var viewModel: ProductsListViewModel

    @State private var isPresentingCreate = false
    @State private var isPresentingFilters = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.products.isEmpty {
                    ProgressView("Загружаем продукты")
                } else if let error = viewModel.errorMessage, viewModel.products.isEmpty {
                    ContentUnavailableView("Ошибка", systemImage: "exclamationmark.triangle", description: Text(error))
                } else if viewModel.products.isEmpty {
                    ContentUnavailableView("Пусто", systemImage: "shippingbox", description: Text("Добавьте первый продукт"))
                } else {
                    List {
                        ForEach(viewModel.products) { product in
                            NavigationLink {
                                ProductDetailView(
                                    viewModel: ProductDetailViewModel(productId: product.id, useCases: viewModel.useCases),
                                    makeEditorViewModel: { ProductEditorViewModel(editingProduct: $0, useCases: viewModel.useCases) },
                                    onChanged: { await viewModel.load() }
                                )
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    RemoteThumbnailView(urlString: product.photos.first, size: 64)

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(product.name)
                                            .font(.headline)
                                        HStack {
                                            Text(product.category.title)
                                            Text("•")
                                            Text(product.preparation.title)
                                        }
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                        Text("К: \(product.calories, specifier: "%.0f") Б: \(product.proteins, specifier: "%.1f") Ж: \(product.fats, specifier: "%.1f") У: \(product.carbs, specifier: "%.1f")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { await viewModel.deleteProduct(id: product.id) }
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Продукты")
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
                if viewModel.products.isEmpty {
                    await viewModel.load()
                }
            }
            .refreshable {
                await viewModel.load()
            }
        }
        .sheet(isPresented: $isPresentingCreate) {
            ProductEditorView(
                viewModel: ProductEditorViewModel(editingProduct: nil, useCases: viewModel.useCases),
                onSaved: { await viewModel.load() }
            )
        }
        .sheet(isPresented: $isPresentingFilters) {
            ProductFiltersSheet(filters: $viewModel.filters) {
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

private struct ProductFiltersSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filters: ProductListFilters
    let onApply: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Категория") {
                    Picker("Категория", selection: $filters.category) {
                        Text("Любая").tag(ProductCategory?.none)
                        ForEach(ProductCategory.allCases) { value in
                            Text(value.title).tag(ProductCategory?.some(value))
                        }
                    }
                }

                Section("Подготовка") {
                    Picker("Подготовка", selection: $filters.preparation) {
                        Text("Любая").tag(PreparationStatus?.none)
                        ForEach(PreparationStatus.allCases) { value in
                            Text(value.title).tag(PreparationStatus?.some(value))
                        }
                    }
                }

                Section("Сортировка") {
                    Picker("Поле", selection: $filters.sortBy) {
                        ForEach(ProductSortField.allCases) { value in
                            Text(value.title).tag(value)
                        }
                    }
                    Picker("Порядок", selection: $filters.sortOrder) {
                        ForEach(SortOrder.allCases) { value in
                            Text(value.title).tag(value)
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
                        filters = ProductListFilters()
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
