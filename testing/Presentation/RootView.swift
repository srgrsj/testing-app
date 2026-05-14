import SwiftUI

struct RootView: View {
    @EnvironmentObject private var container: AppContainer

    var body: some View {
        TabView {
            ProductsListView(viewModel: ProductsListViewModel(useCases: container.useCases))
                .tabItem {
                    Label("Продукты", systemImage: "shippingbox")
                }

            DishesListView(viewModel: DishesListViewModel(useCases: container.useCases))
                .tabItem {
                    Label("Блюда", systemImage: "fork.knife")
                }

            ApiInfoView(viewModel: ApiInfoViewModel(useCase: container.useCases.apiInfo))
                .tabItem {
                    Label("API", systemImage: "network")
                }
        }
    }
}
