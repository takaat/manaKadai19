//
//  ContentView.swift
//  Kadai19
//
//  Created by mana on 2022/01/21.
//

import SwiftUI

struct Item: Identifiable, Codable {
    var id = UUID()
    var name: String
    var isChecked: Bool
}

struct ContentView: View {
    private enum Mode {
        case add, edit
    }

    @Environment(\.scenePhase) private var scenePhase
    @State private var isShowAddEditView = false
    @State private var name = ""
    @State private var mode: Mode = .add
    @State private var editId = UUID()
    @State private var items: [Item] = []

    var body: some View {
        NavigationView {
            List {
                ForEach($items) { $item in
                    HStack {
                        ItemView(item: $item)
                            .onTapGesture {
                                item.isChecked.toggle()
                            }

                        Spacer()

                        Label("", systemImage: "info.circle")
                            .onTapGesture {
                                mode = .edit
                                editId = item.id
                                name = item.name
                                isShowAddEditView = true
                            }
                    }
                }
                .onDelete { items.remove(atOffsets: $0) }
            }
            .listStyle(.plain)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        mode = .add
                        name = ""
                        isShowAddEditView = true
                    }, label: { Image(systemName: "plus") })
                }
            }
        }
        .fullScreenCover(isPresented: $isShowAddEditView) {
            AddOrEditItemView(
                name: $name,
                didSave: { item, editName in
                    isShowAddEditView = false
                    switch mode {
                    case .add:
                        items.append(item)
                    case .edit:
                        guard let targetIndex = items.firstIndex(where: { $0.id == editId }) else { return }
                        items[targetIndex].name = editName
                    }
                },
                didCancel: { isShowAddEditView = false })
        }
        .onChange(of: scenePhase) { newScenePhase in
            let dataStore = ItemDataStore()

            switch newScenePhase {
            case .active:
                do {
                    items = try dataStore.load() ?? []
                } catch {
                    print("読み込みエラー")
                }
            case .inactive:
                do {
                    try dataStore.save(items: items)
                } catch {
                    print("書き込みエラー")
                }
            default:
                break
            }
        }
    }
}

struct ItemDataStore {
    enum Error: Swift.Error {
        case encodingError
        case decodingError
    }

    private let key = "storageItems"

    func save(items: [Item]) throws {
        do {
            let encodeItems = try JSONEncoder().encode(items)
            UserDefaults.standard.set(encodeItems, forKey: key)
        } catch {
            throw Error.encodingError
        }
    }

    func load() throws -> [Item]? {
        guard let decodeItems = UserDefaults.standard.data(forKey: key) else {
            return nil
        }

        do {
            return try JSONDecoder().decode([Item].self, from: decodeItems)
        } catch {
            throw Error.decodingError
        }
    }
}

struct AddOrEditItemView: View {
    @Binding var name: String
    let didSave: (Item, String) -> Void
    let didCancel: () -> Void

    var body: some View {
        NavigationView {
            HStack(spacing: 30) {
                Text("名前")
                    .padding(.leading)

                TextField("", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .padding(.trailing)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        didCancel()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        didSave(.init(name: name, isChecked: false), name)
                    }
                }
            }
        }
    }
}

struct ItemView: View {
    @Binding var item: Item
    private let checkMark = Image(systemName: "checkmark")

    var body: some View {
        HStack {
            if item.isChecked {
                checkMark.foregroundColor(.orange)
            } else {
                checkMark.hidden()
            }

            Text(item.name)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct AddOrEditItemView_Previews: PreviewProvider {
    static var previews: some View {
        AddOrEditItemView(name: .constant("みかん"), didSave: { _, _ in }, didCancel: {})
    }
}

struct ItemView_Previews: PreviewProvider {
    static var previews: some View {
        ItemView(item: .constant(.init(name: "みかん", isChecked: true)))
    }
}
