import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct FileBrowserView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @StateObject private var viewModel: FileBrowserViewModel
    @State private var layoutMode: BrowserLayoutMode = .grid
    @State private var sortMode: BrowserSortMode = .name
    @State private var searchText = ""
    @State private var isFileImporterPresented = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isCreateFolderPresented = false
    @State private var folderName = ""
    @State private var renameItem: WebDAVItem?
    @State private var renameText = ""
    @State private var deleteItem: WebDAVItem?

    private let client: WebDAVClient
    private let cache: DiskCache

    init(path: String, client: WebDAVClient, cache: DiskCache) {
        self.client = client
        self.cache = cache
        _viewModel = StateObject(wrappedValue: FileBrowserViewModel(path: path, client: client, cache: cache))
    }

    var body: some View {
        ZStack {
            UnifiedBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    BrowserHeroView(
                        title: viewModel.title,
                        path: viewModel.path,
                        isOnline: session.isOnline,
                        metrics: viewModel.metrics,
                        itemCount: visibleItems.count,
                        cachedCount: viewModel.cachedEntries.count
                    )

                    breadcrumbBar

                    BrowserControlBar(
                        layoutMode: $layoutMode,
                        sortMode: $sortMode,
                        createFolder: {
                            folderName = ""
                            isCreateFolderPresented = true
                        },
                        uploadFile: {
                            isFileImporterPresented = true
                        }
                    )

                    content
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
            .refreshable {
                await refresh()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Image(systemName: "photo.badge.plus")
                }
                .accessibilityLabel("Carica foto")

                Button {
                    Task { await refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Aggiorna")
            }

            ToolbarItem(placement: .navigationBarLeading) {
                Button(role: .destructive) {
                    session.disconnect()
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                }
                .accessibilityLabel("Disconnetti")
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Cerca in questa cartella")
        .task {
            await refresh()
        }
        .fileImporter(isPresented: $isFileImporterPresented, allowedContentTypes: [.item], allowsMultipleSelection: false) { result in
            Task {
                guard let url = try? result.get().first else { return }
                let online = await viewModel.upload(fileURL: url)
                session.setOnline(online)
            }
        }
        .onChange(of: selectedPhoto) { newValue in
            Task {
                let online = await viewModel.upload(photoItem: newValue)
                selectedPhoto = nil
                session.setOnline(online)
            }
        }
        .sheet(item: $viewModel.previewItem) { item in
            QuickLookPreview(url: item.url)
        }
        .sheet(item: $viewModel.shareItem) { item in
            ShareSheet(activityItems: [item.url])
        }
        .sheet(item: $viewModel.playerContext) { context in
            PlayerPreviewView(context: context)
        }
        .alert("Crea cartella", isPresented: $isCreateFolderPresented) {
            TextField("Nome", text: $folderName)
            Button("Annulla", role: .cancel) {}
            Button("Crea") {
                Task {
                    let online = await viewModel.createFolder(named: folderName)
                    session.setOnline(online)
                }
            }
        }
        .alert("Rinomina", isPresented: Binding(
            get: { renameItem != nil },
            set: { if !$0 { renameItem = nil } }
        )) {
            TextField("Nome", text: $renameText)
            Button("Annulla", role: .cancel) {
                renameItem = nil
            }
            Button("Salva") {
                guard let renameItem else { return }
                Task {
                    let online = await viewModel.rename(item: renameItem, to: renameText)
                    session.setOnline(online)
                    self.renameItem = nil
                }
            }
        }
        .confirmationDialog("Elimina elemento", isPresented: Binding(
            get: { deleteItem != nil },
            set: { if !$0 { deleteItem = nil } }
        )) {
            Button("Elimina", role: .destructive) {
                guard let deleteItem else { return }
                Task {
                    let online = await viewModel.delete(item: deleteItem)
                    session.setOnline(online)
                    self.deleteItem = nil
                }
            }
            Button("Annulla", role: .cancel) {
                deleteItem = nil
            }
        }
        .alert("Errore", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingPanel
        case .loaded:
            if visibleItems.isEmpty {
                emptyPanel
            } else if layoutMode == .grid {
                gridContent
            } else {
                listContent
            }
        case .failed(let message):
            offlinePanel(message: message)
        }
    }

    private var gridContent: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 158), spacing: 14)], spacing: 14) {
            ForEach(visibleItems) { item in
                itemButton(item) {
                    FinderTileView(item: item)
                }
            }
        }
    }

    private var listContent: some View {
        LazyVStack(spacing: 10) {
            ForEach(visibleItems) { item in
                itemButton(item) {
                    FinderListRowView(item: item)
                }
            }
        }
    }

    private var loadingPanel: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Sincronizzo la cartella")
                .font(.subheadline.weight(.medium))
            Spacer()
        }
        .padding(18)
        .adaptiveGlass(cornerRadius: 20)
    }

    private var emptyPanel: some View {
        VStack(spacing: 12) {
            Image(systemName: searchText.isEmpty ? "folder" : "magnifyingglass")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(searchText.isEmpty ? "Cartella vuota" : "Nessun risultato")
                .font(.headline)
            Text(searchText.isEmpty ? "Carica un file, una foto o crea una cartella." : "Prova un nome o un tipo diverso.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .adaptiveGlass(cornerRadius: 24)
    }

    private func offlinePanel(message: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Hub offline, cache attiva", systemImage: "wifi.slash")
                .font(.headline)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if !viewModel.cachedEntries.isEmpty {
                Text("File apribili ora")
                    .font(.subheadline.weight(.semibold))
                    .padding(.top, 4)

                LazyVStack(spacing: 10) {
                    ForEach(viewModel.cachedEntries) { entry in
                        Button {
                            viewModel.openCached(entry)
                        } label: {
                            FinderListRowView(item: entry.item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(18)
        .adaptiveGlass(cornerRadius: 24, tint: .orange.opacity(0.12))
    }

    private var breadcrumbBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(breadcrumbs.indices, id: \.self) { index in
                    let crumb = breadcrumbs[index]
                    if crumb.path == viewModel.path {
                        Text(crumb.title)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .adaptiveGlass(cornerRadius: 14)
                    } else {
                        NavigationLink {
                            FileBrowserView(path: crumb.path, client: client, cache: cache)
                        } label: {
                            Text(crumb.title)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .adaptiveGlass(cornerRadius: 14, isInteractive: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func itemButton<Content: View>(_ item: WebDAVItem, @ViewBuilder label: () -> Content) -> some View {
        Group {
            if item.isDirectory {
                NavigationLink {
                    FileBrowserView(path: item.path, client: client, cache: cache)
                } label: {
                    label()
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    Task {
                        await viewModel.open(item)
                    }
                } label: {
                    label()
                }
                .buttonStyle(.plain)
            }
        }
        .contextMenu {
            if !item.isDirectory {
                Button {
                    Task { await viewModel.share(item) }
                } label: {
                    Label("Condividi", systemImage: "square.and.arrow.up")
                }

                Button {
                    Task { await viewModel.cacheForOffline(item) }
                } label: {
                    Label("Tieni offline", systemImage: "internaldrive")
                }
            }

            Button {
                renameText = item.name
                renameItem = item
            } label: {
                Label("Rinomina", systemImage: "pencil")
            }

            Button(role: .destructive) {
                deleteItem = item
            } label: {
                Label("Elimina", systemImage: "trash")
            }
        }
    }

    private var visibleItems: [WebDAVItem] {
        let filtered = viewModel.items.filter { item in
            searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            item.name.localizedCaseInsensitiveContains(searchText)
        }

        return filtered.sorted { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory {
                return lhs.isDirectory && !rhs.isDirectory
            }

            switch sortMode {
            case .name:
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            case .kind:
                return lhs.type.rawValue.localizedStandardCompare(rhs.type.rawValue) == .orderedAscending
            case .modified:
                return (lhs.lastModified ?? .distantPast) > (rhs.lastModified ?? .distantPast)
            case .size:
                return (lhs.size ?? -1) > (rhs.size ?? -1)
            }
        }
    }

    private var breadcrumbs: [BrowserCrumb] {
        let trimmed = viewModel.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !trimmed.isEmpty else {
            return [BrowserCrumb(title: "UnifiedDrive", path: "/")]
        }

        var result: [BrowserCrumb] = [BrowserCrumb(title: "UnifiedDrive", path: "/")]
        var accumulated = "/"

        for part in trimmed.split(separator: "/") {
            accumulated = WebDAVPath.childPath(parent: accumulated, name: String(part), isDirectory: true)
            result.append(BrowserCrumb(title: String(part), path: accumulated))
        }

        return result
    }

    private func refresh() async {
        let online = await viewModel.load()
        session.setOnline(online)
    }
}

private struct BrowserCrumb {
    let title: String
    let path: String
}
