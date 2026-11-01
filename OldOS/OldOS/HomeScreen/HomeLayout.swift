import Foundation

struct HomeApplication: Identifiable, Equatable {
    let id: String
    let image: String
    let category: String
    static let all: [HomeApplication] = [
        .init(id:"Messages",image:"Messages",category:"Social"),
        .init(id:"Calendar",image:"Calendar",category:"Productivity"),
        .init(id:"Photos",image:"Photos",category:"Photography"),
        .init(id:"Camera",image:"Camera",category:"Photography"),
        .init(id:"YouTube",image:"YouTube",category:"Entertainment"),
        .init(id:"Stocks",image:"Stocks",category:"Finance"),
        .init(id:"Maps",image:"Maps",category:"Navigation"),
        .init(id:"Weather",image:"Weather Fahrenheit",category:"Weather"),
        .init(id:"Notes",image:"Notes",category:"Productivity"),
        .init(id:"iTunes",image:"iTunes",category:"Stores"),
        .init(id:"App Store",image:"App Store",category:"Stores"),
        .init(id:"Game Center",image:"Game Center",category:"Games"),
        .init(id:"Settings",image:"Settings",category:"Utilities"),
        .init(id:"Contacts",image:"Contacts",category:"Productivity"),
        .init(id:"Phone",image:"Phone",category:"Social"),
        .init(id:"Mail",image:"Mail",category:"Productivity"),
        .init(id:"Safari",image:"Safari",category:"Utilities"),
        .init(id:"iPod",image:"iPod",category:"Music"),
        .init(id:"Clock",image:"Clock",category:"Utilities"),
        .init(id:"Calculator",image:"Calculator",category:"Utilities"),
        .init(id:"Compass",image:"Compass",category:"Utilities"),
        .init(id:"Voice Memos",image:"Voice Memos",category:"Utilities")
    ]
    static let identifiers = Set(all.map(\.id))
    static func named(_ id:String) -> HomeApplication? { all.first{$0.id == id} }
}

enum HomeNode: Codable, Hashable, Identifiable {
    case app(String), folder(String)
    var id: String {
        switch self { case .app(let id): return "app:"+id; case .folder(let id): return "folder:"+id }
    }
    var application: String? { if case .app(let id) = self { return id }; return nil }
    var folderID: String? { if case .folder(let id) = self { return id }; return nil }
}

struct HomeFolder: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var apps: [String]
}

enum HomeContainer: Hashable {
    case page(Int), dock, folder(String)
}
struct HomeLocation: Equatable {
    var container: HomeContainer
    var index: Int
}

struct HomeLayout: Codable, Equatable {
    static let pageCapacity = 16, dockCapacity = 4, folderCapacity = 12, maximumPages = 11
    var version = 1
    var pages: [[HomeNode]]
    var dock: [HomeNode]
    var folders: [String:HomeFolder]
    static var initial: HomeLayout {
        HomeLayout(pages:[[
            .app("Messages"),.app("Calendar"),.app("Photos"),.app("Camera"),
            .app("YouTube"),.app("Stocks"),.app("Maps"),.app("Weather"),
            .app("Notes"),.folder("utilities"),.app("iTunes"),.app("App Store"),
            .app("Game Center"),.app("Settings")
        ],[.app("Contacts")]],dock:[.app("Phone"),.app("Mail"),.app("Safari"),.app("iPod")],
        folders:["utilities":HomeFolder(id:"utilities",name:"Utilities",apps:["Clock","Calculator","Compass","Voice Memos"])])
    }
    func nodes(in container:HomeContainer) -> [HomeNode] {
        switch container {
        case .page(let index): return pages.indices.contains(index) ? pages[index] : []
        case .dock: return dock
        case .folder(let id): return folders[id]?.apps.map(HomeNode.app) ?? []
        }
    }
    func location(of node:HomeNode) -> HomeLocation? {
        for (page,items) in pages.enumerated() {
            if let index = items.firstIndex(of:node) { return HomeLocation(container:.page(page),index:index) }
        }
        if let index = dock.firstIndex(of:node) { return HomeLocation(container:.dock,index:index) }
        if let app = node.application {
            for folder in folders.values {
                if let index = folder.apps.firstIndex(of:app) { return HomeLocation(container:.folder(folder.id),index:index) }
            }
        }
        return nil
    }
    func isInsideFolder(_ app:String) -> Bool {
        if case .folder? = location(of:.app(app))?.container { return true }; return false
    }
    func isValid(allowEmptyFolders:Bool=false) -> Bool {
        guard version == 1, !pages.isEmpty, pages.count <= Self.maximumPages,
              pages.allSatisfy({$0.count <= Self.pageCapacity}), dock.count <= Self.dockCapacity else { return false }
        let top = pages.flatMap{$0}+dock
        guard Set(top).count == top.count else { return false }
        let folderIDs = top.compactMap(\.folderID)
        guard Set(folderIDs) == Set(folders.keys) else { return false }
        var apps = top.compactMap(\.application)
        for (key,folder) in folders {
            guard key == folder.id, !folder.name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,
                  folder.name.count <= 32, folder.apps.count <= Self.folderCapacity,
                  allowEmptyFolders || !folder.apps.isEmpty else { return false }
            apps += folder.apps
        }
        return apps.count == HomeApplication.identifiers.count && Set(apps) == HomeApplication.identifiers
    }
    @discardableResult mutating func move(_ node:HomeNode,to destination:HomeContainer,index:Int) -> Bool {
        var next = self
        guard let source = next.location(of:node) else { return false }
        if case .folder(let folder) = destination {
            guard node.application != nil, next.folders[folder] != nil else { return false }
        }
        next.remove(at:source)
        guard next.insert(node,in:destination,index:index), next.isValid(allowEmptyFolders:true) else { return false }
        self = next; return true
    }
    @discardableResult mutating func makeFolder(dragging app:String,onto target:String,id:String=UUID().uuidString) -> String? {
        guard app != target, folders[id] == nil else { return nil }
        var next = self
        guard let source = next.location(of:.app(app)), let targetLocation = next.location(of:.app(target)) else { return nil }
        if case .folder = targetLocation.container { return nil }
        next.remove(at:source)
        guard let place = next.location(of:.app(target)) else { return nil }
        next.remove(at:place)
        let firstCategory = HomeApplication.named(target)?.category ?? "Folder"
        let name = firstCategory
        next.folders[id] = HomeFolder(id:id,name:name,apps:[target,app])
        guard next.insert(.folder(id),in:place.container,index:place.index), next.isValid(allowEmptyFolders:true) else { return nil }
        self = next; return id
    }
    @discardableResult mutating func renameFolder(_ id:String,name:String) -> Bool {
        let name = String(name.trimmingCharacters(in:.whitespacesAndNewlines).prefix(32))
        guard !name.isEmpty, folders[id] != nil else { return false }
        folders[id]?.name = name; return true
    }
    mutating func normalize() {
        let empty = Set(folders.values.filter{$0.apps.isEmpty}.map(\.id))
        for id in empty { folders.removeValue(forKey:id) }
        pages = pages.map{$0.filter{!empty.contains($0.folderID ?? "")}}.filter{!$0.isEmpty}
        dock.removeAll{empty.contains($0.folderID ?? "")}
        if pages.isEmpty { pages = [[]] }
    }
    private mutating func remove(at location:HomeLocation) {
        switch location.container {
        case .page(let page): pages[page].remove(at:location.index)
        case .dock: dock.remove(at:location.index)
        case .folder(let id): folders[id]?.apps.remove(at:location.index)
        }
    }
    private mutating func insert(_ node:HomeNode,in container:HomeContainer,index:Int) -> Bool {
        switch container {
        case .dock:
            guard dock.count < Self.dockCapacity else { return false }
            dock.insert(node,at:min(max(0,index),dock.count))
        case .folder(let id):
            guard let app = node.application, let folder = folders[id], folder.apps.count < Self.folderCapacity else { return false }
            folders[id]?.apps.insert(app,at:min(max(0,index),folder.apps.count))
        case .page(let page):
            guard page >= 0, page < Self.maximumPages else { return false }
            while pages.count <= page { pages.append([]) }
            pages[page].insert(node,at:min(max(0,index),pages[page].count))
            var cursor = page
            while pages[cursor].count > Self.pageCapacity {
                let overflow = pages[cursor].removeLast(); cursor += 1
                guard cursor < Self.maximumPages else { return false }
                if pages.count == cursor { pages.append([]) }
                pages[cursor].insert(overflow,at:0)
            }
        }
        return true
    }
}

struct HomeLayoutRepository {
    var defaults: UserDefaults = .standard
    var key = "OldOS.HomeLayout.v1"
    func load() -> HomeLayout {
        guard let data = defaults.data(forKey:key) else { return .initial }
        guard let layout = try? JSONDecoder().decode(HomeLayout.self,from:data), layout.isValid() else {
            defaults.set(data,forKey:key+".invalidBackup"); return .initial
        }
        return layout
    }
    @discardableResult func save(_ layout:HomeLayout) -> Bool {
        guard layout.isValid(), let data = try? JSONEncoder().encode(layout) else { return false }
        defaults.set(data,forKey:key); return true
    }
}
