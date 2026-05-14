import SwiftUI

struct ApiInfoView: View {
    @StateObject var viewModel: ApiInfoViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Запрашиваем API")
                } else if let info = viewModel.apiInfo {
                    List {
                        LabeledContent("Название", value: info.name)
                        LabeledContent("Версия", value: info.version)
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    ContentUnavailableView(
                        "Ошибка",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                } else {
                    ContentUnavailableView("Нет данных", systemImage: "tray")
                }
            }
            .navigationTitle("Состояние API")
            .task {
                if viewModel.apiInfo == nil {
                    await viewModel.load()
                }
            }
            .refreshable {
                await viewModel.load()
            }
        }
    }
}
