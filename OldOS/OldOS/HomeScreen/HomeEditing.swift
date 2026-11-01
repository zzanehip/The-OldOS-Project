import SwiftUI
import UIKit

struct HomeIconAddress: Hashable {
    let node: HomeNode
    let container: HomeContainer
}
struct HomeFrames: Equatable {
    var icons: [HomeIconAddress:CGRect] = [:]
    var pages: [Int:CGRect] = [:]
    var dock: CGRect = .zero
    var folder: CGRect = .zero
    func relative(to origin:CGPoint) -> HomeFrames {
        HomeFrames(icons:icons.mapValues{$0.offsetBy(dx:-origin.x,dy:-origin.y)},
                   pages:pages.mapValues{$0.offsetBy(dx:-origin.x,dy:-origin.y)},
                   dock:dock == .zero ? .zero:dock.offsetBy(dx:-origin.x,dy:-origin.y),
                   folder:folder == .zero ? .zero:folder.offsetBy(dx:-origin.x,dy:-origin.y))
    }
    mutating func merge(_ other:HomeFrames) {
        icons.merge(other.icons,uniquingKeysWith:{$1}); pages.merge(other.pages,uniquingKeysWith:{$1})
        if other.dock != .zero { dock = other.dock }
        if other.folder != .zero { folder = other.folder }
    }
}
struct HomeFramesKey: PreferenceKey {
    static var defaultValue = HomeFrames()
    static func reduce(value:inout HomeFrames,nextValue:()->HomeFrames) { value.merge(nextValue()) }
}
struct HomeLift: Equatable {
    let node: HomeNode
    let originPoint: CGPoint
    let grabOffset: CGSize
    let cellSize: CGSize
    let sourceContainer:HomeContainer
}

enum HomeHover: Equatable {
    case position(HomeContainer,Int)
    case combine(HomeNode)
    case none
}

struct HomeFolderFormation:Equatable {
    let id:String
    let target:String
    let dragged:String
    let frame:CGRect
    var folder:HomeFolder { HomeFolder(id:id,name:HomeApplication.named(target)?.category ?? "Folder",apps:[target,dragged]) }
}

struct HomeFolderAnchor:Equatable {
    let container:HomeContainer
    let row:Int
    let splitY:CGFloat
    let triangleX:CGFloat
}

struct HomeFolderPresentation:Equatable {
    static let notchHeight:CGFloat = 12
    static let duration:Double = 0.4
    static let highlightFadeDuration:Double = 2.0/15.0
    static let highlightCloseDelay:Double = duration-highlightFadeDuration
    let progress:CGFloat
    let splitY:CGFloat
    let upperShift:CGFloat
    let lowerShift:CGFloat
    let triangleX:CGFloat
    let pointsDown:Bool
    let bodyHeight:CGFloat
    var notchHeight:CGFloat { Self.notchHeight }
    var wallpaperNotchHeight:CGFloat { Self.notchHeight*(1-progress) }
    var panelHeight:CGFloat { bodyHeight+notchHeight }
    var panelTop:CGFloat { pointsDown ? splitY-bodyHeight:splitY+upperShift-notchHeight }
    var contentTopInset:CGFloat { (pointsDown ? 0:notchHeight)+6 }
}

struct HomeFolderHighlightStroke {
    let points:[CGPoint]
    let opacity:Double
}

struct HomeFolderHighlightEdge {
    let width:CGFloat
    let cutY:CGFloat
    let triangleX:CGFloat
    let notchHeight:CGFloat
    let upper:Bool
    private var hasNotch:Bool { abs(notchHeight)>0.0001 }
    private var halfBase:CGFloat { notchHeight<0 ? min(12,-notchHeight):12 }
    private var bevelInset:CGFloat { min(1,abs(notchHeight)) }
    var straightRects:[CGRect] {
        let y=cutY-(upper ? 1:0)
        guard hasNotch else { return [CGRect(x:0,y:y,width:width,height:1)] }
        let left=max(0,min(width,triangleX-halfBase-bevelInset)), right=max(0,min(width,triangleX+halfBase+bevelInset))
        return [CGRect(x:0,y:y,width:left,height:1),CGRect(x:right,y:y,width:width-right,height:1)]
    }
    var notchStrokes:[HomeFolderHighlightStroke] {
        guard hasNotch else { return [] }
        let direction:CGFloat=upper ? -1:1
        let tip=cutY+direction*notchHeight
        return [HomeFolderHighlightStroke(points:[CGPoint(x:triangleX-halfBase-bevelInset,y:cutY),CGPoint(x:triangleX,y:tip+direction*bevelInset),CGPoint(x:triangleX+halfBase+bevelInset,y:cutY)],opacity:0.4),
                HomeFolderHighlightStroke(points:[CGPoint(x:triangleX-halfBase-bevelInset,y:cutY+direction*bevelInset),CGPoint(x:triangleX,y:tip+direction*bevelInset*2),CGPoint(x:triangleX+halfBase+bevelInset,y:cutY+direction*bevelInset)],opacity:0.15)]
    }
}

struct HomeFolderShadowPiece:Equatable {
    let asset:String
    let frame:CGRect
}

struct HomeFolderArtworkLayout {
    let width:CGFloat
    let bodyHeight:CGFloat
    let triangleX:CGFloat
    let pointsDown:Bool
    static func titleLeadingInset(panelWidth:CGFloat,screenWidth:CGFloat)->CGFloat {
        let column=screenWidth/(390/85), icon=screenWidth/(390/60)
        return max(0,(panelWidth-column*4-3)/2+(column-icon)/2+icon/59)
    }
    var shadows:[HomeFolderShadowPiece] {
        let notch:CGFloat=12, half:CGFloat=12, topHeight:CGFloat=24, bottomHeight:CGFloat=27
        let bodyTop:CGFloat=pointsDown ? 0:notch
        let left=min(width,max(0,triangleX-half)), right=min(width,max(0,triangleX+half))
        func piece(_ name:String,_ x:CGFloat,_ y:CGFloat,_ w:CGFloat,_ h:CGFloat)->HomeFolderShadowPiece {
            HomeFolderShadowPiece(asset:"Home-"+name,frame:CGRect(x:x,y:y,width:max(0,w),height:h))
        }
        if pointsDown {
            return [piece("FolderShadowTop",0,0,width,topHeight),
                    piece("FolderShadowBottom",0,bodyHeight-bottomHeight,left,bottomHeight),
                    piece("FolderShadowBottom",right,bodyHeight-bottomHeight,width-right,bottomHeight),
                    piece("FolderShadowBottomNotch",triangleX-half,bodyHeight+notch-40,24,40)]
        }
        return [piece("FolderShadowTop",0,bodyTop,left,topHeight),
                piece("FolderShadowTop",right,bodyTop,width-right,topHeight),
                piece("FolderShadowTopNotch",triangleX-half,0,24,39),
                piece("FolderShadowBottom",0,bodyTop+bodyHeight-bottomHeight,width,bottomHeight)]
    }
}

final class HomeDragPosition:ObservableObject { @Published var point:CGPoint = .zero }

final class HomeEditingController: ObservableObject {
    let dragPosition = HomeDragPosition()
    @Published private(set) var layout: HomeLayout {
        didSet { if let id=displayedFolderID, let folder=layout.folders[id] { folderSnapshot=folder } }
    }
    @Published private(set) var isEditing = false
    @Published private(set) var folderEditingDuringClose = false
    @Published var page = 0
    @Published var openFolderID: String? {
        didSet {
            if let id=openFolderID {
                if displayedFolderID != id { folderAnchor=anchor(for:id); folderEditingDuringClose=false }
                folderSnapshot=layout.folders[id]; displayedFolderID=id
            }
        }
    }
    private var folderAnchor:HomeFolderAnchor?
    private var folderSnapshot:HomeFolder?
    @Published private(set) var formation:HomeFolderFormation?
    @Published private(set) var formationProgress:CGFloat = 0
    @Published private(set) var formationShrink:CGFloat = 0
    @Published private(set) var formationGlow:Double = 1
    @Published private(set) var droppingIntoFolder:String?
    @Published private(set) var dropScale:CGFloat = 1
    @Published private(set) var displayedFolderID: String?
    @Published private(set) var lift: HomeLift?
    @Published private(set) var dropping: HomeLift?
    private var dropRevision = UUID()
    @Published private(set) var movementDelays:[HomeNode:Double] = [:]
    @Published private(set) var hoverFolder: HomeNode?
    @Published var renamingFolder = false
    private let repository: HomeLayoutRepository
    private var original: HomeLayout?
    private var frames = HomeFrames()
    private var closedFrames = HomeFrames()
    private var candidate: HomeHover = .none
    private var folderEntryPoint: CGPoint?
    private var dwell: DispatchWorkItem?
    private var edgeWork: DispatchWorkItem?
    private var edgeDirection = 0
    private var exitWork: DispatchWorkItem?
    private var hoverRevision = UUID()
    private var edgeRevision = UUID()
    private var exitRevision = UUID()
    private var geometrySize: CGSize = .zero
    private var columnWidth: CGFloat = 85
    private var rowGap: CGFloat = 40
    private var cellHeight: CGFloat = 84
    private var pageOrigin: CGPoint = .zero
    private var pagePitch: CGFloat = 124
    var displayPageCount: Int { layout.pages.count }
    private var availablePageCount: Int {
        min(HomeLayout.maximumPages,layout.pages.count + (isEditing && !(layout.pages.last?.isEmpty ?? true) ? 1:0))
    }
    init(repository:HomeLayoutRepository = HomeLayoutRepository()) {
        self.repository = repository; layout = repository.load()
    }
    func selectPage(_ index:Int) {
        guard index >= 0, index < availablePageCount else { return }
        if index >= layout.pages.count { layout.pages.append([]) }
        page=index
    }
    func configure(size:CGSize,columnWidth:CGFloat,rowGap:CGFloat) {
        geometrySize = size; self.columnWidth = columnWidth; self.rowGap = rowGap
    }
    func updateFrames(_ value:HomeFrames) {
        frames = value
        if displayedFolderID == nil {
            closedFrames = value
            guard lift == nil, dropping == nil else { return }
            let current = value.icons.filter{$0.key.container == .page(page)}
            let nodes = layout.nodes(in:.page(page))
            if let first = nodes.first, let frame = current[HomeIconAddress(node:first,container:.page(page))] {
                pageOrigin = CGPoint(x:frame.midX-columnWidth/2,y:frame.minY); cellHeight = frame.height
                pagePitch = frame.height+rowGap
                if nodes.count > 4, let secondRow = current[HomeIconAddress(node:nodes[4],container:.page(page))] {
                    pagePitch = secondRow.minY-frame.minY
                }
            }
        }
    }
    func showsDockReflection(for node:HomeNode) -> Bool {
        lift?.node != node && layout.location(of:node)?.container == .dock
    }
    func source(at point:CGPoint) -> HomeIconAddress? {
        let registry = openFolderID == nil && displayedFolderID != nil ? closedFrames:frames
        return registry.icons.filter { address,rect in
            let active: Bool
            if let folder = openFolderID { active = address.container == .folder(folder) }
            else { active = address.container == .page(page) || address.container == .dock }
            return active && rect.contains(point)
        }.min(by:{$0.value.width*$0.value.height < $1.value.width*$1.value.height})?.key
    }
    func enterEditing(from address:HomeIconAddress) {
        guard layout.location(of:address.node)?.container == address.container else { return }
        if !isEditing { isEditing = true }
    }
    static func pressDuration(editing:Bool,folder:Bool) -> Double { editing ? (folder ? 0.15:0):0.6 }
    func begin(at point:CGPoint) {
        guard lift == nil, let source = source(at:point), let frame = frames.icons[source] else { return }
        dropRevision = UUID(); dropping = nil; droppingIntoFolder=nil; dropScale=1
        isEditing = true; original = layout; candidate = .none; folderEntryPoint = nil
        dragPosition.point = point
        lift = HomeLift(node:source.node,originPoint:point,grabOffset:CGSize(width:frame.midX-point.x,height:frame.midY-point.y),cellSize:frame.size,sourceContainer:source.container)
    }
    func update(at point:CGPoint) {
        guard lift != nil else { return }
        dragPosition.point = point
        if let formation, layout.folders[formation.id] == nil {
            if target(at:point) == .combine(.app(formation.target)) { return }
            self.formation=nil; formationProgress=0; formationGlow=1; candidate = .none
        }
        if let folder = openFolderID {
            if frames.folder.insetBy(dx:-14,dy:-14).contains(point) {
                folderEntryPoint = nil
                exitWork?.cancel(); exitWork = nil; exitRevision = UUID()
            } else if let entry = folderEntryPoint, hypot(point.x-entry.x,point.y-entry.y) < columnWidth*0.55 {
                exitWork?.cancel(); exitWork = nil; exitRevision = UUID()
            } else if exitWork == nil {
                let revision = UUID(); exitRevision = revision
                let work = DispatchWorkItem { [weak self] in
                    guard let self, self.lift != nil, self.openFolderID == folder, self.exitRevision == revision else { return }
                    self.openFolderID = nil; self.folderEntryPoint = nil; self.renamingFolder = false; self.exitWork = nil
                    self.candidate = .none; self.update(at:self.dragPosition.point)
                }; exitWork = work; DispatchQueue.main.asyncAfter(deadline:.now()+0.25,execute:work)
            }
        }
        updateEdge(at:point)
        let target = target(at:point)
        if target != candidate {
            dwell?.cancel(); hoverRevision = UUID(); hoverFolder = nil; candidate = target
            switch target {
            case .combine(let node):
                hoverFolder = node
                if node.application != nil { combine(with:node); break }
                let revision = hoverRevision
                let work = DispatchWorkItem { [weak self] in
                    guard let self, self.hoverRevision == revision else { return }
                    self.combine(with:node)
                }
                dwell = work; DispatchQueue.main.asyncAfter(deadline:.now()+0.8,execute:work)
            case .position: break
            case .none: break
            }
        }
        if case .position(let container,let index)=target {
            dwell?.cancel();hoverRevision=UUID()
            let revision=hoverRevision
            let work=DispatchWorkItem { [weak self] in
                guard let self, self.lift != nil, self.hoverRevision == revision, self.candidate == .position(container,index) else { return }
                self.previewMove(to:container,index:index)
            }
            dwell=work;DispatchQueue.main.asyncAfter(deadline:.now()+0.04,execute:work)
        }
    }
    func end(at point:CGPoint) {
        guard let lift else { return }
        cancelTimers()
        var createdFolder:String?
        if let pending=formation, layout.folders[pending.id] != nil || target(at:point) == .combine(.app(pending.target)) {
            var next=layout
            if layout.folders[pending.id] != nil {
                if openFolderID != pending.id { createdFolder=pending.id }
            } else if let id=next.makeFolder(dragging:pending.dragged,onto:pending.target,id:pending.id) {
                withAnimation(.easeInOut(duration:0.2)) { layout=next }
                createdFolder=id
            }
        }
        if createdFolder != nil {
            formationGlow=1
            withAnimation(.easeInOut(duration:0.5)) { formationShrink=1 }
        } else if formation.flatMap({layout.folders[$0.id]}) == nil { formation=nil; formationProgress=0 }
        let destination = target(at:point)
        let keepsNewFolder = openFolderID != nil && folderEntryPoint.map{hypot(point.x-$0.x,point.y-$0.y) < columnWidth*0.55} == true
        var accepted = keepsNewFolder || createdFolder != nil
        switch accepted ? .none:destination {
        case .position(let container,let index): accepted = previewMove(to:container,index:index)
        case .combine(let node):
            if let folder = node.folderID { accepted = previewMove(to:.folder(folder),index:layout.folders[folder]?.apps.count ?? 0) }
            else if let location = layout.location(of:node) { accepted = previewMove(to:location.container,index:location.index) }
        case .none:
            if !keepsNewFolder, createdFolder == nil, openFolderID != nil && !frames.folder.contains(point) {
                openFolderID = nil
                switch target(at:point) {
                case .position(let container,let index): accepted = previewMove(to:container,index:index)
                case .combine(let node):
                    if let folder = node.folderID { accepted = previewMove(to:.folder(folder),index:layout.folders[folder]?.apps.count ?? 0) }
                    else if let location = layout.location(of:node) { accepted = previewMove(to:location.container,index:location.index) }
                case .none: break
                }
            }
        }
        if !accepted, let original { layout = original }
        var result = layout; result.normalize()
        if result.isValid() { layout = result; repository.save(result) }
        var location = layout.location(of:lift.node)
        if case .folder(let id)? = location?.container { location = layout.location(of:.folder(id)) }
        if case .page(let index)? = location?.container { page = index }
        page = min(page,max(0,layout.pages.count-1))
        settle(lift,opening:createdFolder)
        original = nil; candidate = .none; folderEntryPoint = nil
        if let id = openFolderID, layout.folders[id] == nil { openFolderID = nil }
    }
    func cancelDrag() {
        dropRevision = UUID(); dropping = nil; droppingIntoFolder=nil; dropScale=1
        formation=nil; formationProgress=0
        cancelTimers()
        if let original { layout = original }
        original = nil; lift = nil; hoverFolder = nil; candidate = .none; folderEntryPoint = nil
        page = min(page,max(0,layout.pages.count-1))
        if let id = openFolderID, layout.folders[id] == nil { openFolderID = nil }
    }
    func finishEditing() {
        if isEditing, displayedFolderID != nil { folderEditingDuringClose=true }
        if lift != nil { end(at:dragPosition.point) }
        dropRevision = UUID(); dropping = nil; droppingIntoFolder=nil; dropScale=1
        formation=nil; formationProgress=0
        cancelTimers(); isEditing = false; renamingFolder = false
        var result = layout; result.normalize(); layout = result; repository.save(result)
        if let id = openFolderID, case .page(let index)? = layout.location(of:.folder(id))?.container { page = index }
        page = min(page,max(0,layout.pages.count-1))
        UIApplication.shared.endEditing()
    }
    func clearClosedFolder() {
        if openFolderID == nil { displayedFolderID=nil; folderAnchor=nil; folderSnapshot=nil; folderEditingDuringClose=false }
    }
    var displayedFolder:HomeFolder? {
        displayedFolderID.flatMap{layout.folders[$0]} ?? folderSnapshot
    }
    func openFolder(_ id:String) {
        guard layout.folders[id] != nil else { return }
        if openFolderID == id { openFolderID = nil; renamingFolder = false }
        else { openFolderID = id; renamingFolder = false }
    }
    func rename(_ id:String,name:String) {
        guard lift == nil else { return }
        var result = layout
        if result.renameFolder(id,name:name) { layout = result; repository.save(result) }
    }
    @discardableResult private func previewMove(to container:HomeContainer,index:Int) -> Bool {
        guard let lift else { return false }
        var next = layout
        guard next.move(lift.node,to:container,index:index) else { return false }
        if next != layout {
            var delays:[HomeNode:Double]=[:]
            var containers:[HomeContainer]=next.pages.indices.map(HomeContainer.page)+[.dock]
            containers += next.folders.keys.sorted().map(HomeContainer.folder)
            for list in containers {
                var delay=0.0
                for (index,node) in next.nodes(in:list).enumerated() where node != lift.node {
                    if layout.location(of:node) != HomeLocation(container:list,index:index) {
                        delays[node]=delay;delay += 0.045
                    }
                }
            }
            movementDelays=delays
            withAnimation(.easeInOut(duration:0.225)) { layout = next }
        }
        return true
    }
    private func combine(with node:HomeNode) {
        guard let lift, candidate == .combine(node), let app = lift.node.application else { return }
        if let id = node.folderID {
            guard let folder = layout.folders[id], folder.apps.count < HomeLayout.folderCapacity || folder.apps.contains(app),
                  previewMove(to:.folder(id),index:folder.apps.count) else { return }
            openFolderID = id
        } else if let target = node.application {
            guard let location=layout.location(of:node),
                  let measured=(displayedFolderID == nil ? frames:closedFrames).icons[HomeIconAddress(node:node,container:location.container)] else { return }
            let frame=closedFrame(for:HomeIconAddress(node:node,container:location.container),size:measured.size) ?? measured
            let pending=HomeFolderFormation(id:UUID().uuidString,target:target,dragged:app,frame:frame)
            formation=pending; formationProgress=0; formationShrink=0; formationGlow=1; hoverFolder=nil; candidate = .none
            DispatchQueue.main.async { [weak self] in
                guard let self, self.formation?.id == pending.id else { return }
                withAnimation(.easeInOut(duration:0.225)) { self.formationProgress=1 }
            }
            let work=DispatchWorkItem { [weak self] in self?.pulseFormation(pending) }
            dwell=work;DispatchQueue.main.asyncAfter(deadline:.now()+0.8,execute:work)
            return
        }
        folderEntryPoint = dragPosition.point
        hoverFolder = nil; candidate = .none
    }
    private func pulseFormation(_ pending:HomeFolderFormation) {
        guard formation?.id == pending.id, lift != nil else { return }
        for step in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline:.now()+Double(step)*0.1) { [weak self] in
                guard let self, self.formation?.id == pending.id, self.lift != nil else { return }
                withAnimation(.linear(duration:0.1)) { self.formationGlow=step%2 == 0 ? 0.5:1 }
            }
        }
        DispatchQueue.main.asyncAfter(deadline:.now()+0.4) { [weak self] in
            guard let self, self.formation?.id == pending.id, self.lift != nil else { return }
            var next=self.layout
            guard next.makeFolder(dragging:pending.dragged,onto:pending.target,id:pending.id) != nil else { return }
            withAnimation(.easeInOut(duration:0.15)) { self.layout=next }
            self.folderEntryPoint=self.dragPosition.point;self.candidate = .none;self.hoverFolder=nil
            self.openFolderID=pending.id
            DispatchQueue.main.async {
                guard self.formation?.id == pending.id else { return }
                withAnimation(.easeInOut(duration:0.5)) { self.formationShrink=1 }
            }
            DispatchQueue.main.asyncAfter(deadline:.now()+0.5) { [weak self] in
                guard let self, self.formation?.id == pending.id else { return }
                self.formation=nil;self.formationProgress=0;self.formationShrink=0;self.formationGlow=1
            }
        }
    }
    private func settle(_ icon:HomeLift,opening folderToOpen:String?=nil) {
        let revision = UUID(); dropRevision = revision
        let duration:Double=folderToOpen == nil ? 0.225:0.5
        let delay:Double=folderToOpen == nil ? 0.025:0.2
        droppingIntoFolder=nil; dropScale=1
        withAnimation(.easeOut(duration:0.225)) { dropping = icon; lift = nil; hoverFolder = nil }
        DispatchQueue.main.asyncAfter(deadline:.now()+delay) { [weak self] in
            guard let self, self.dropRevision == revision, self.dropping != nil else { return }
            var address = self.layout.location(of:icon.node).map{HomeIconAddress(node:icon.node,container:$0.container)}
            var destinationFolder:String?
            if let current = address, case .folder(let id) = current.container, self.openFolderID != id {
                destinationFolder=id
                address = self.layout.location(of:.folder(id)).map{HomeIconAddress(node:.folder(id),container:$0.container)}
            }
            let registry = self.openFolderID == nil && self.displayedFolderID != nil ? self.closedFrames:self.frames
            let frame = address.flatMap{self.openFolderID == nil && self.displayedFolderID != nil ? self.closedFrame(for:$0,size:icon.cellSize):registry.icons[$0]}
            var point = frame.map{CGPoint(x:$0.midX-icon.grabOffset.width,y:$0.midY-icon.grabOffset.height)} ?? icon.originPoint
            var scale:CGFloat=1
            if let id=destinationFolder, let folder=self.layout.folders[id], let app=icon.node.application,
               let index=folder.apps.firstIndex(of:app), let frame {
                let size=self.columnWidth*60/85, mini=self.columnWidth/6.5, spacing=size/(844/40)
                scale=mini/size
                let left=(size-(mini*3+spacing*2))/2
                point=CGPoint(x:frame.midX-size/2+left+mini/2+CGFloat(index%3)*(mini+spacing)-icon.grabOffset.width,
                              y:frame.minY+spacing*2.65+mini/2+CGFloat(min(index/3,2))*(mini+spacing)+(icon.cellSize.height-size)/2*scale-icon.grabOffset.height)
                self.droppingIntoFolder=id
            }
            withAnimation(.easeInOut(duration:duration)) { self.dropScale=scale; self.dragPosition.point = point }
            DispatchQueue.main.asyncAfter(deadline:.now()+duration) { [weak self] in
                guard let self, self.dropRevision == revision else { return }
                var transaction=Transaction();transaction.disablesAnimations=true
                withTransaction(transaction) { self.dropping=nil;self.droppingIntoFolder=nil;self.dropScale=1 }
                if let id=folderToOpen, self.layout.folders[id] != nil {
                    self.formation=nil;self.formationProgress=0;self.formationShrink=0;self.formationGlow=1
                    self.openFolder(id)
                }
            }
        }
    }
    private func recipientPoint(at point:CGPoint) -> CGPoint {
        guard let lift else { return point }
        let size=columnWidth*60/85
        return CGPoint(x:point.x+lift.grabOffset.width,y:point.y+lift.grabOffset.height-(lift.cellSize.height-size)/2)
    }
    private func closedFrame(for address:HomeIconAddress,size:CGSize) -> CGRect? {
        guard let location=layout.location(of:address.node) else { return nil }
        switch location.container {
        case .page:
            let center=pageOrigin.x+columnWidth/2+CGFloat(location.index%4)*(columnWidth+1)
            return CGRect(x:center-size.width/2,y:pageOrigin.y+CGFloat(location.index/4)*pagePitch,width:size.width,height:size.height)
        case .dock:
            let count=max(1,layout.dock.count), dock=closedFrames.dock
            let left=(dock.width-columnWidth*CGFloat(count)-CGFloat(count-1))/2
            let center=dock.minX+left+columnWidth/2+CGFloat(location.index)*(columnWidth+1)
            let top=closedFrames.icons.filter{$0.key.container == .dock}.map{$0.value.minY}.min() ?? dock.maxY-cellHeight
            return CGRect(x:center-size.width/2,y:top,width:size.width,height:size.height)
        case .folder: return nil
        }
    }
    private func target(at point:CGPoint) -> HomeHover {
        guard let lift else { return .none }
        if let id = openFolderID {
            guard frames.folder.insetBy(dx:0,dy:8).contains(point) else { return .none }
            let children = layout.nodes(in:.folder(id))
            guard let first = children.first,
                  let frame = frames.icons[HomeIconAddress(node:first,container:.folder(id))] else { return .position(.folder(id),0) }
            let origin = CGPoint(x:frame.midX-columnWidth/2,y:frame.minY)
            let secondRow = children.count > 4 ? frames.icons[HomeIconAddress(node:children[4],container:.folder(id))]:nil
            let pitch = secondRow.map{$0.minY-frame.minY} ?? (frame.height+rowGap)
            let column = min(3,max(0,Int((point.x-origin.x)/(columnWidth+1))))
            let row = min(2,max(0,Int((point.y-origin.y)/max(1,pitch))))
            return .position(.folder(id),min(children.count,row*4+column))
        }
        let registry = displayedFolderID != nil ? closedFrames:frames
        let active = registry.icons.filter{$0.key.container == .page(page) || $0.key.container == .dock}
        let dock = registry.dock.height > 1 ? registry.dock:closedFrames.dock
        let dockTop=active.filter{$0.key.container == .dock}.map{$0.value.minY}.min() ?? dock.maxY-cellHeight
        if dock.contains(point), point.y >= dockTop-12 {
            let count = layout.dock.count
            let nodes=layout.dock
            let centers=nodes.compactMap { node -> (HomeNode,CGRect)? in
                let address=HomeIconAddress(node:node,container:.dock)
                guard let measured=registry.icons[address] ?? closedFrames.icons[address] else { return nil }
                return (node,closedFrame(for:address,size:measured.size) ?? measured)
            }
            let recipient=recipientPoint(at:point)
            if let nearest=centers.min(by:{abs($0.1.midX-recipient.x)<abs($1.1.midX-recipient.x)}),let index=nodes.firstIndex(of:nearest.0) {
                return orderedTarget(node:nearest.0,frame:nearest.1,container:.dock,index:index,at:recipient)
            }
            return .position(.dock,count)
        }
        let pageFrame=registry.pages[page] ?? closedFrames.pages[page] ?? .zero
        if pageFrame.contains(point) || (point.x >= 0 && point.x <= geometrySize.width && point.y >= pageFrame.minY && point.y < dockTop-12) {
            let recipient=recipientPoint(at:point),index=pageIndex(at:recipient),nodes=layout.pages[page]
            if nodes.indices.contains(index) {
                let node=nodes[index],address=HomeIconAddress(node:node,container:.page(page))
                let measured=registry.icons[address] ?? closedFrames.icons[address] ?? CGRect(x:0,y:0,width:columnWidth,height:cellHeight)
                if let slot=closedFrame(for:address,size:measured.size) { return orderedTarget(node:node,frame:slot,container:.page(page),index:index,at:recipient) }
            }
            return .position(.page(page),min(index,nodes.count))
        }
        return .none
    }
    private func orderedTarget(node:HomeNode,frame:CGRect,container:HomeContainer,index:Int,at point:CGPoint) -> HomeHover {
        guard let lift else { return .none }
        if node == lift.node { return .position(container,index) }
        let scale=columnWidth/85,bandWidth:CGFloat=(node.folderID == nil ? 35:50)*scale
        let band=CGRect(x:frame.midX-bandWidth/2,y:frame.minY,width:bandWidth,height:frame.height)
        let sourceFolder:Bool
        if case .folder(let id)=lift.sourceContainer { sourceFolder=node.folderID == id } else { sourceFolder=false }
        let canReceive=lift.node.application != nil && !sourceFolder && (node.folderID.flatMap{layout.folders[$0]?.apps.count}.map{$0<HomeLayout.folderCapacity} ?? true)
        if canReceive && band.contains(point) { return .combine(node) }
        if !canReceive { return .position(container,index) }
        let boundary=index+(point.x>band.maxX ? 1:0)
        let source=layout.location(of:lift.node)
        let finalIndex=boundary-((source?.container == container && (source?.index ?? Int.max)<boundary) ? 1:0)
        return .position(container,max(0,finalIndex))
    }
    private func pageIndex(at point:CGPoint) -> Int {
        let horizontalPadding=max(0,columnWidth+1-columnWidth*60/85)
        let right=pageOrigin.x+columnWidth/2+columnWidth*60/85/2+horizontalPadding/2
        let column=min(3,max(0,Int(floor((point.x-right)/(columnWidth+1)))+1))
        let bottom=pageOrigin.y+cellHeight+(pagePitch-cellHeight)/2
        let row=min(3,max(0,Int(floor((point.y-bottom)/max(1,pagePitch)))+1))
        return min(layout.nodes(in:.page(page)).count,row*4+column)
    }
    private func updateEdge(at point:CGPoint) {
        guard openFolderID == nil else { edgeWork?.cancel(); edgeWork = nil; edgeDirection = 0; edgeRevision = UUID(); return }
        let direction = point.x < 18 ? -1 : point.x > geometrySize.width-18 ? 1:0
        guard direction != edgeDirection else { return }
        edgeWork?.cancel(); edgeWork = nil; edgeDirection = direction; edgeRevision = UUID()
        guard direction != 0 else { return }
        scheduleEdge(direction)
    }
    private func scheduleEdge(_ direction:Int) {
        let revision = edgeRevision
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.lift != nil, self.edgeDirection == direction, self.edgeRevision == revision else { return }
            let destination = min(max(0,self.page+direction),self.availablePageCount-1)
            if destination != self.page {
                if destination >= self.layout.pages.count { self.layout.pages.append([]) }
                self.candidate = .none; self.dwell?.cancel(); self.hoverRevision = UUID(); self.hoverFolder = nil
                withAnimation(.easeInOut(duration:0.3)) { self.page = destination }
                self.scheduleEdge(direction)
            }
        }; edgeWork = work; DispatchQueue.main.asyncAfter(deadline:.now()+0.65,execute:work)
    }
    private func cancelTimers() {
        hoverRevision = UUID(); edgeRevision = UUID(); exitRevision = UUID()
        dwell?.cancel(); dwell = nil; edgeWork?.cancel(); edgeWork = nil; edgeDirection = 0
        exitWork?.cancel(); exitWork = nil
    }
    private func anchor(for id:String) -> HomeFolderAnchor? {
        guard let location=layout.location(of:.folder(id)) else { return nil }
        let address=HomeIconAddress(node:.folder(id),container:location.container)
        let registry=closedFrames.icons[address] == nil ? frames:closedFrames
        let frame=registry.icons[address] ?? closedFrame(for:address,size:CGSize(width:columnWidth,height:cellHeight+columnWidth*60/85*2/59))
        let dock=location.container == .dock
        let fallbackY=dock ? geometrySize.height-84:pageOrigin.y+CGFloat(location.index/4)*pagePitch
        let tip=dock ? (frame?.minY ?? fallbackY)-6:(frame?.maxY ?? fallbackY+cellHeight)+6
        return HomeFolderAnchor(container:location.container,row:location.index/4,
                                splitY:dock ? tip-HomeFolderPresentation.notchHeight:tip+HomeFolderPresentation.notchHeight,
                                triangleX:frame?.midX ?? 10+columnWidth*(CGFloat(location.index%4)+0.5))
    }
    var folderIsInDock:Bool { folderAnchor?.container == .dock }
    var folderPanelHeight:CGFloat {
        let count=displayedFolder?.apps.count ?? 4
        return 150+CGFloat(max(0,(count+3)/4-1))*(cellHeight+rowGap)
    }
    var folderAnchorRow:Int { folderAnchor?.row ?? 2 }
    var folderTriangleX:CGFloat { folderAnchor?.triangleX ?? 10+columnWidth*1.5 }
    func folderPresentation(reveal:CGFloat) -> HomeFolderPresentation {
        let height=folderPanelHeight, notch=HomeFolderPresentation.notchHeight
        let body=max(1,height-notch), p=min(1,max(0,reveal/max(1,height)))
        let split=folderAnchor?.splitY ?? 3*(columnWidth+rowGap)
        let upper=folderIsInDock ? -body:min(0,max(54,geometrySize.height-body)-split)
        return HomeFolderPresentation(progress:p,splitY:split,upperShift:upper*p,
                                      lowerShift:(folderIsInDock ? 0:upper+body)*p,
                                      triangleX:folderTriangleX,pointsDown:folderIsInDock,bodyHeight:body)
    }
    var folderPanelTop:CGFloat { folderPresentation(reveal:folderPanelHeight).panelTop }
    var upperFolderShift:CGFloat { folderPresentation(reveal:folderPanelHeight).upperShift }

}

struct HomeGestureHost: UIViewRepresentable {
    let controller: HomeEditingController
    let active: Bool
    func makeCoordinator() -> Coordinator { Coordinator(controller:controller) }
    func makeUIView(context:Context) -> Reporter {
        let view = Reporter(); view.isUserInteractionEnabled = false; view.coordinator = context.coordinator
        return view
    }
    func updateUIView(_ view:Reporter,context:Context) {
        context.coordinator.active = active
        if context.coordinator.longPress.state != .began && context.coordinator.longPress.state != .changed {
            context.coordinator.longPress.minimumPressDuration = controller.isEditing ? 0.15:0.6
        }
        if context.coordinator.longPress.isEnabled != active { context.coordinator.longPress.isEnabled = active }
        context.coordinator.connect(view)
    }
    static func dismantleUIView(_ view:Reporter,coordinator:Coordinator) { coordinator.disconnect() }
    final class Reporter:UIView {
        weak var coordinator:Coordinator?
        override func didMoveToWindow() { super.didMoveToWindow(); coordinator?.connect(self) }
    }
    final class Coordinator:NSObject,UIGestureRecognizerDelegate {
        let controller:HomeEditingController
        var active = true
        weak var canvas: UIView?
        weak var window: UIWindow?
        lazy var longPress:UILongPressGestureRecognizer = {
            let gesture = UILongPressGestureRecognizer(target:self,action:#selector(changed(_:)))
            gesture.delegate = self; gesture.minimumPressDuration = 0.6; gesture.allowableMovement = 12
            gesture.cancelsTouchesInView = true; return gesture
        }()
        init(controller:HomeEditingController) { self.controller = controller }
        func connect(_ view:UIView) {
            canvas = view
            guard let target = view.window else { window?.removeGestureRecognizer(longPress); window = nil; return }
            guard target !== window else { return }
            window?.removeGestureRecognizer(longPress); window = target; target.addGestureRecognizer(longPress)
        }
        func disconnect() { window?.removeGestureRecognizer(longPress); window = nil; canvas = nil; controller.cancelDrag() }
        private var hasModalAlert:Bool {
            let clock = RetroClockStore.shared
            return clock.soundingAlarm != nil || (clock.timerFinished && clock.timerSound != "Sleep iPod") || clock.notificationError != nil || OldOSPasscodeStore.shared.isLocked || OldOSPasscodeStore.shared.inactive
        }
        func gestureRecognizer(_ gestureRecognizer:UIGestureRecognizer,shouldReceive touch:UITouch) -> Bool {
            guard active, !hasModalAlert, let canvas else { return false }
            guard let source = controller.source(at:touch.location(in:canvas)) else { return false }
            if gestureRecognizer.state == .possible {
                longPress.minimumPressDuration = HomeEditingController.pressDuration(editing:controller.isEditing,folder:source.node.folderID != nil)
            }
            return true
        }
        func gestureRecognizer(_ gestureRecognizer:UIGestureRecognizer,shouldRecognizeSimultaneouslyWith other:UIGestureRecognizer) -> Bool {
            !(other is UIPanGestureRecognizer)
        }
        @objc private func changed(_ recognizer:UILongPressGestureRecognizer) {
            guard !hasModalAlert else { controller.cancelDrag(); return }
            guard let canvas else { return }
            let point = recognizer.location(in:canvas)
            switch recognizer.state {
            case .began: controller.begin(at:point)
            case .changed: controller.update(at:point)
            case .ended: controller.end(at:point)
            case .cancelled,.failed: controller.cancelDrag()
            default: break
            }
        }
    }
}
