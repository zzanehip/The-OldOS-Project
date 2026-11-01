import SwiftUI
import UIKit

struct HomeAnimationProgress<Content:View>:View,Animatable {
    var progress:CGFloat
    @ViewBuilder var content:(CGFloat)->Content
    var animatableData:CGFloat { get { progress } set { progress=newValue } }
    var body:some View { content(progress).animation(nil,value:progress) }
}

struct HomeWiggle: ViewModifier {
    let enabled: Bool
    let identifier: String
    func body(content:Content) -> some View {
        TimelineView(.animation(minimumInterval:1/30,paused:!enabled)) { timeline in
            let seed=Double(identifier.utf8.reduce(0){($0+Int($1))%127})
            let phase=timeline.date.timeIntervalSinceReferenceDate*34+seed
            content.rotationEffect(.degrees(enabled ? sin(phase)*1.35:0)).offset(y:enabled ? cos(phase*0.9)*0.35:0)
                .animation(nil,value:enabled ? phase:0)
        }
    }
}

struct HomeFolderFace: View {
    let folder: HomeFolder
    var hiddenApplications:Set<String> = []
    @State private var date = Date()
    private var size:CGFloat { UIScreen.main.bounds.width/(390/60) }
    private var spacing:CGFloat { size/(844/40) }
    private var miniatureWidth:CGFloat { UIScreen.main.bounds.width/(390/85*6.5) }
    var body: some View {
        ZStack {
            Image("Folder").resizable().scaledToFit().frame(width:size)
            VStack(alignment:.center) {
                VStack(alignment:.leading,spacing:spacing) {
                    ForEach(Array(Array(folder.apps.prefix(9)).chunked(into:3).enumerated()),id:\.offset) { _,row in
                        HStack(spacing:spacing) {
                            ForEach(row,id:\.self) { app in
                                let small = app+"-Small"
                                miniature(app,small:small).frame(width:miniatureWidth).opacity(hiddenApplications.contains(app) ? 0:1)
                            }
                        }
                    }
                }.frame(width:miniatureWidth*3+spacing*2,alignment:.leading).frame(width:size,alignment:.center).padding(.top,spacing*2.65).padding(.leading,size/(844/40*100))
                Spacer()
            }
        }
    }
    @ViewBuilder private func miniature(_ app:String,small:String) -> some View {
        let width = UIScreen.main.bounds.width/(390/85*6.5)
        Image(UIImage(named:small) != nil ? small : HomeApplication.named(app)?.image ?? app).resizable().scaledToFit()
            .overlay {
                if app == "Calendar" {
                    ZStack {
                        VStack {
                            Text(Calendar.current.weekdaySymbols[Calendar.current.component(.weekday,from:date)-1])
                                .font(.custom("Helvetica Neue Medium",fixedSize:width/6)).foregroundColor(.white).lineLimit(1).minimumScaleFactor(0.5)
                            Spacer(minLength:0)
                        }.padding(.top,width/30)
                        Text(String(Calendar.current.component(.day,from:date))).font(.custom("Helvetica Neue Bold",fixedSize:width*35/60))
                            .foregroundColor(.black).padding(.top,width/6)
                    }
                }
            }
    }
}

struct HomeFormingFolderIcon:View {
    let formation:HomeFolderFormation
    let progress:CGFloat
    let shrink:CGFloat
    let glow:Double
    private var size:CGFloat { UIScreen.main.bounds.width/(390/60) }
    private var mini:CGFloat { UIScreen.main.bounds.width/(390/85*6.5) }
    var body:some View {
        let spacing=size/(844/40), left=(size-mini*3-spacing*2)/2
        VStack {
            ZStack {
                ZStack {
                    HomeFolderFace(folder:formation.folder,hiddenApplications:[formation.target,formation.dragged])
                        .scaleEffect(1+0.24561405*progress*(1-shrink))
                    Image("Home-FolderDropBG").resizable().scaledToFit()
                        .frame(width:size*176/59,height:size*176/59)
                        .scaleEffect(0.80281693+(1-0.80281693)*progress*(1-shrink))
                        .opacity(1-shrink)
                }.frame(width:size,height:size)
                    .opacity(progress*(shrink+(1-shrink)*glow))
                    .animation(.linear(duration:0.1),value:glow)
                Group {
                    if formation.target == "Calendar" {
                        app_calendar(image_name:"Calendar",app_name:"Calendar",current_view:.constant("HS"),apps_scale:.constant(1),dock_offset:.constant(0),folder_offset:.constant(0),canLaunch:false,shadowOverride:false)
                            .fixedSize(horizontal:false,vertical:true).frame(width:size,height:size,alignment:.top).clipped()
                    } else {
                        Image(HomeApplication.named(formation.target)?.image ?? formation.target).resizable().scaledToFit()
                    }
                }.frame(width:size,height:size)
                    .scaleEffect(1+(mini/size-1)*shrink)
                    .offset(x:(left+mini/2-size/2)*shrink,y:(spacing*2.65+mini/2-size/2)*shrink)
            }.frame(width:size,height:size)
            ZStack {
                Text(formation.target).opacity(1-shrink)
                Text(formation.folder.name).opacity(shrink)
            }.foregroundColor(.white).font(.custom("Helvetica Neue Medium",fixedSize:13)).lineLimit(1)
                .shadow(color:.black.opacity(0.9),radius:0.75,x:0,y:1.75).offset(y:-4)
        }.allowsHitTesting(false)
    }
}

struct HomeFolderIcon: View {
    let folder: HomeFolder
    let shadow: Bool
    let action: ()->Void
    var body: some View {
        Button(action:action) {
            VStack {
                HomeFolderFace(folder:folder)
                Text(folder.name).foregroundColor(.white).font(.custom("Helvetica Neue Medium",fixedSize:13)).lineLimit(1)
                    .shadow(color:Color.black.opacity(0.9),radius:0.75,x:0,y:1.75).offset(y:-4)
            }
        }.background {
            if shadow { Image("WallpaperIconShadow").resizable().scaledToFit().frame(width:UIScreen.main.bounds.width/(390/104)).offset(y:6) }
        }.compositingGroup()
    }
}

struct HomeIconTouchStyle:ButtonStyle {
    func makeBody(configuration:Configuration) -> some View { configuration.label }
}

struct HomeIconCell: View {
    @EnvironmentObject private var home:HomeEditingController
    let node: HomeNode
    let container: HomeContainer
    @Binding var current_view:String
    @Binding var apps_scale:CGFloat
    @Binding var dock_offset:CGFloat
    @Binding var folder_offset:CGFloat
    var quadrantOffset:CGPoint = .zero
    private var inFolder:Bool { if case .folder = container { return true }; return false }
    private var inDock:Bool { container == .dock }
    private var folderProgress:CGFloat { min(1,max(0,folder_offset/max(1,home.folderPanelHeight))) }
    private var dimsForFolder:Bool { !inFolder && (node.folderID == nil || node.folderID != home.displayedFolderID) }
    var body: some View {
        graphic.buttonStyle(HomeIconTouchStyle())
            .background(alignment:.top) {
                if inDock && home.showsDockReflection(for:node) {
                    HomeDockReflection(node:node).transition(.identity)
                }
            }
            .background(alignment:.top) {
                if home.hoverFolder == node {
                    Image("Home-FolderDropBG").resizable().scaledToFit()
                        .frame(width:UIScreen.main.bounds.width/(390/60)+12,height:UIScreen.main.bounds.width/(390/60)+12)
                        .offset(y:-6).allowsHitTesting(false)
                }
            }
            .modifier(HomeWiggle(enabled:home.isEditing && home.lift?.node != node && home.dropping?.node != node && (home.formation == nil || (home.formation?.target != node.application && home.formation?.id != node.folderID)),identifier:node.id))
            .grayscale(dimsForFolder ? 0.99*folderProgress:0)
            .opacity(dimsForFolder ? 1-0.7*folderProgress:1)
            .simultaneousGesture(LongPressGesture(minimumDuration:0.6,maximumDistance:12).onEnded { _ in
                home.enterEditing(from:HomeIconAddress(node:node,container:container))
            },including:home.isEditing ? .subviews:.all)
            .background(GeometryReader { proxy in
                Color.clear.preference(key:HomeFramesKey.self,value:HomeFrames(icons:[HomeIconAddress(node:node,container:container):proxy.frame(in:.global)]))
            })
            .opacity(home.lift?.node == node || home.dropping?.node == node ? 0:1)
            .animation(nil,value:home.lift?.node == node || home.dropping?.node == node)
    }
    @ViewBuilder private var graphic:some View {
        switch node {
        case .app(let id):
            if let pending=home.formation, pending.target == id, !inFolder {
                HomeFormingFolderIcon(formation:pending,progress:home.formationProgress,shrink:home.formationShrink,glow:home.formationGlow)
            } else if id == "Calendar" {
                app_calendar(image_name:"Calendar",app_name:id,current_view:$current_view,apps_scale:$apps_scale,dock_offset:$dock_offset,folder_offset:.constant(0),
                             is_folder_app:inFolder,canLaunch:!home.isEditing,launchAllowed:{!home.isEditing},shadowOverride:!inDock,quadrantOffset:quadrantOffset)
            } else {
                app(image_name:HomeApplication.named(id)?.image ?? id,app_name:id,current_view:$current_view,apps_scale:$apps_scale,dock_offset:$dock_offset,folder_offset:.constant(0),
                    is_folder_app:inFolder,canLaunch:!home.isEditing,launchAllowed:{!home.isEditing},shadowOverride:!inDock,quadrantOffset:quadrantOffset)
            }
        case .folder(let id):
            if let folder = home.layout.folders[id] {
                if let pending=home.formation, pending.id == id {
                    HomeFormingFolderIcon(formation:pending,progress:home.formationProgress,shrink:home.formationShrink,glow:home.formationGlow)
                } else {
                HomeFolderIcon(folder:folder,shadow:!inDock) {
                    if home.lift == nil && home.dropping == nil { home.openFolder(id) }
                }
                    .offset(x:quadrantOffset.x,y:quadrantOffset.y)
                }
            }
        }
    }
}

struct HomePageIcons: View {
    @EnvironmentObject private var home:HomeEditingController
    @Binding var apps_scale:CGFloat
    @Binding var apps_scale_height:CGFloat
    @Binding var show_searchField:Bool
    @Binding var icon_scaler:CGFloat
    @Binding var current_view:String
    @Binding var dock_offset:CGFloat
    @Binding var folder_offset:CGFloat
    let page:Int
    let isActivePage:Bool
    var body: some View {
        VStack {
            LazyVGrid(columns:Array(repeating:GridItem(.fixed(UIScreen.main.bounds.width/(390/85)),spacing:1),count:4),
                      spacing:UIScreen.main.bounds.height/(844/40)*icon_scaler) {
                ForEach(Array(home.layout.nodes(in:.page(page)).enumerated()),id:\.element.id) { index,node in
                    HomeIconCell(node:node,container:.page(page),current_view:$current_view,apps_scale:$apps_scale,dock_offset:$dock_offset,folder_offset:$folder_offset,quadrantOffset:flight(index))
                        .offset(y:folderShift(index))
                        .animation(.easeInOut(duration:0.225).delay(home.movementDelays[node] ?? 0),value:index)
                }
            }
            Spacer()
        }
        .background(GeometryReader { proxy in
            Color.clear.preference(key:HomeFramesKey.self,value:HomeFrames(pages:[page:proxy.frame(in:.global)]))
        })
        .opacity(isActivePage || apps_scale <= 1.001 ? 1:0)
        .allowOverflowFromPagingContainer()
        .background(HomeIconEntranceDriver(isActive:current_view == "HS" && isActivePage) {
            guard current_view == "HS", apps_scale > 1.001 else { return }
            withAnimation(.easeInOut(duration:0.5)) { apps_scale = 1; dock_offset = 0; apps_scale_height = 1 }
        }.allowsHitTesting(false).accessibilityHidden(true))
        .onAppear { UIApplication.shared.endEditing() }
    }
    private func flight(_ index:Int) -> CGPoint {
        let progress = min(max((apps_scale-1)/3,0),1)
        return CGPoint(x:UIScreen.main.bounds.width*0.6*progress*(index%4<2 ? -1:1),
                       y:UIScreen.main.bounds.height*0.45*progress*(index/4<2 ? -1:1))
    }
    private func folderShift(_ index:Int) -> CGFloat {
        guard home.displayedFolderID != nil else { return 0 }
        let motion=home.folderPresentation(reveal:folder_offset)
        return index/4 > home.folderAnchorRow && !motion.pointsDown ? motion.lowerShift:motion.upperShift
    }
}

struct HomeFolderApps: View {
    @EnvironmentObject private var home:HomeEditingController
    @Binding var current_view:String
    @Binding var apps_scale:CGFloat
    @Binding var dock_offset:CGFloat
    @Binding var folder_offset:CGFloat
    let iconScaler:CGFloat
    var body: some View {
        LazyVGrid(columns:Array(repeating:GridItem(.fixed(UIScreen.main.bounds.width/(390/85)),spacing:1),count:4),
                  spacing:UIScreen.main.bounds.height/(844/40)*iconScaler) {
            if let id = home.displayedFolderID {
                ForEach(home.layout.nodes(in:.folder(id))) { node in
                    HomeIconCell(node:node,container:.folder(id),current_view:$current_view,apps_scale:$apps_scale,dock_offset:$dock_offset,folder_offset:$folder_offset)
                        .animation(.easeInOut(duration:0.225).delay(home.movementDelays[node] ?? 0),value:home.layout.location(of:node))
                }
            }
        }
    }
}

struct HomeFolderHighlightShape:Shape {
    var cutY:CGFloat
    var triangleX:CGFloat
    var notchHeight:CGFloat
    var progress:CGFloat
    let upper:Bool
    let pass:Int
    var minimumProgress:CGFloat=0
    var animatableData:AnimatablePair<AnimatablePair<CGFloat,CGFloat>,AnimatablePair<CGFloat,CGFloat>> {
        get { .init(.init(cutY,triangleX),.init(notchHeight,progress)) }
        set { cutY=newValue.first.first;triangleX=newValue.first.second;notchHeight=newValue.second.first;progress=newValue.second.second }
    }
    func path(in rect:CGRect)->Path {
        guard progress>minimumProgress else { return Path() }
        let edge=HomeFolderHighlightEdge(width:rect.width,cutY:cutY,triangleX:triangleX,notchHeight:notchHeight,upper:upper)
        var path=Path()
        if pass==0 { for rect in edge.straightRects { path.addRect(rect) } }
        else if edge.notchStrokes.indices.contains(pass-1) { path.addLines(edge.notchStrokes[pass-1].points) }
        return path
    }
}

struct HomeFolderWallpaperHighlights:View {
    @Environment(\.displayScale) private var displayScale
    let motion:HomeFolderPresentation
    var body:some View {
        ZStack {
            edge(upper:true)
                .offset(y:motion.upperShift)
            edge(upper:false)
                .offset(y:motion.lowerShift)
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
    private func edge(upper:Bool)->some View {
        let notch=upper ? (motion.pointsDown ? -motion.wallpaperNotchHeight:motion.notchHeight):(motion.pointsDown ? motion.notchHeight:-motion.wallpaperNotchHeight)
        return ZStack {
            HomeFolderHighlightShape(cutY:motion.splitY,triangleX:motion.triangleX,notchHeight:notch,progress:motion.progress,upper:upper,pass:0,minimumProgress:2/(max(1,displayScale)*max(1,motion.bodyHeight)))
                .fill(.white.opacity(0.3))
            ZStack {
                HomeFolderHighlightShape(cutY:motion.splitY,triangleX:motion.triangleX,notchHeight:notch,progress:motion.progress,upper:upper,pass:1,minimumProgress:2/(max(1,displayScale)*max(1,motion.bodyHeight)))
                    .stroke(.white.opacity(0.4),style:StrokeStyle(lineWidth:1,lineCap:.butt,lineJoin:.miter))
                HomeFolderHighlightShape(cutY:motion.splitY,triangleX:motion.triangleX,notchHeight:notch,progress:motion.progress,upper:upper,pass:2,minimumProgress:2/(max(1,displayScale)*max(1,motion.bodyHeight)))
                    .stroke(.white.opacity(0.15),style:StrokeStyle(lineWidth:1,lineCap:.butt,lineJoin:.miter))
            }.compositingGroup().opacity(0.8)
        }
    }
}

struct HomeFolderShadows:View {
    let layout:HomeFolderArtworkLayout
    var body:some View {
        ZStack(alignment:.topLeading) {
            ForEach(Array(layout.shadows.enumerated()),id:\.offset) { _,piece in
                Image(piece.asset).resizable()
                    .frame(width:piece.frame.width,height:piece.frame.height)
                    .mask {
                        if layout.pointsDown && piece.asset=="Home-FolderShadowBottomNotch" {
                            LinearGradient(stops:[.init(color:.clear,location:0),.init(color:.clear,location:0.25),.init(color:.white,location:0.7),.init(color:.white,location:1)],startPoint:.top,endPoint:.bottom)
                        } else { Color.white }
                    }
                    .opacity(layout.pointsDown && piece.asset=="Home-FolderShadowBottomNotch" ? 0.65:1)
                    .offset(x:piece.frame.minX,y:piece.frame.minY)
            }
        }.frame(width:layout.width,height:layout.bodyHeight+12,alignment:.topLeading)
            .allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct HomeFolderTitle: View {
    var textLeadingInset:CGFloat=8
    @EnvironmentObject private var home:HomeEditingController
    @EnvironmentObject private var keyboard:OldOSKeyboardController
    @State private var draft = ""
    var body: some View {
        Group {
            if home.isEditing || home.folderEditingDuringClose, let id = home.displayedFolderID {
                HStack(spacing:0) {
                OldOSTextField("",text:Binding(get:{draft},set:{draft=String($0.prefix(32)); home.rename(id,name:draft)}),
                               configuration:OldOSKeyboardConfiguration(returnType:.done,autocapitalization:true,autocorrection:false,dismissesOnReturn:true),
                               font:UIFont(name:"HelveticaNeue-Bold",size:20) ?? .boldSystemFont(ofSize:20),textColor:.black,
                               height:29,focusOnAppear:false,onSubmit:{commit(id); keyboard.hide()})
                    .frame(maxWidth:.infinity).frame(height:29)
                    if !draft.isEmpty {
                        Button { draft="" } label: { Image("UITextFieldClearButton").resizable().frame(width:19,height:19).frame(width:25,height:29) }
                            .buttonStyle(HomeIconTouchStyle()).accessibilityLabel("Clear folder name")
                    }
                }.frame(height:29).padding(.leading,textLeadingInset).padding(.trailing,8).background(Image("Home-FolderTitleEditField").resizable(capInsets:EdgeInsets(top:14,leading:14,bottom:14,trailing:14))).frame(height:29)
                    .onChange(of:keyboard.isVisible) { visible in
                        home.renamingFolder = visible
                        if !visible { commit(id) }
                    }
                    .onDisappear { commit(id) }
            } else {
                Text(home.displayedFolder?.name ?? "Utilities")
                    .foregroundColor(.white).font(.custom("Helvetica Neue Bold",fixedSize:21))
                    .frame(height:29)
                    .shadow(color:Color.black.opacity(0.9),radius:0.75,x:0,y:1.75)
            }
        }.onAppear { draft = home.displayedFolder?.name ?? "" }
            .onChange(of:home.displayedFolderID) { _ in draft = home.displayedFolder?.name ?? "" }
    }
    private func commit(_ id:String) {
        if !draft.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty { home.rename(id,name:draft) }
    }
}

struct HomeDockReflection:View {
    @EnvironmentObject private var home:HomeEditingController
    let node:HomeNode
    private var width:CGFloat { UIScreen.main.bounds.width/(390/60) }
    private var imageHeight:CGFloat { node.folderID == nil ? 60:62 }
    private var height:CGFloat { width*imageHeight/59 }
    private var imageOriginY:CGFloat { floor((59-imageHeight)/2) }
    private var artworkAlignmentOffset:CGFloat { width*(node.folderID == nil ? 10:-1)/180 }
    var body:some View {
        artwork.frame(width:width,height:height,alignment:.top).clipped()
            .mask { Image("Home-DockReflectionMask").resizable().frame(width:width,height:height).scaleEffect(x:1,y:1.06,anchor:.bottom) }
            .scaleEffect(x:1,y:-1)
            .offset(y:height-width*(8+imageOriginY)/59+artworkAlignmentOffset)
            .allowsHitTesting(false).accessibilityHidden(true)
    }
    @ViewBuilder private var artwork:some View {
        if let app=node.application {
            if app == "Calendar" {
                app_calendar(image_name:"Calendar",app_name:app,current_view:.constant("HS"),apps_scale:.constant(1),dock_offset:.constant(0),folder_offset:.constant(0),canLaunch:false,shadowOverride:false)
                    .fixedSize(horizontal:false,vertical:true).frame(width:width,height:height,alignment:.top).clipped()
            } else {
                Image(HomeApplication.named(app)?.image ?? app).resizable().scaledToFit()
            }
        } else if let id=node.folderID, let folder=home.layout.folders[id] {
            HomeFolderFace(folder:folder)
        }
    }
}

struct HomeDockIcons: View {
    @EnvironmentObject private var home:HomeEditingController
    @Binding var current_view:String
    @Binding var apps_scale:CGFloat
    @Binding var dock_offset:CGFloat
    @Binding var show_multitasking:Bool
    @Binding var folder_offset:CGFloat
    private var columns:[GridItem] {
        Array(repeating:GridItem(.fixed(UIScreen.main.bounds.width/(390/85)),spacing:1),count:max(1,home.layout.dock.count))
    }
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                Image("SBDockBG 2").resizable().opacity(0.85).frame(height:UIScreen.main.bounds.height/(844/50))
            }
            VStack {
                Spacer()
                ZStack {
                    LazyVGrid(columns:columns,spacing:UIScreen.main.bounds.height/(844/40)) {
                        ForEach(home.layout.dock) { node in
                            HomeIconCell(node:node,container:.dock,current_view:$current_view,apps_scale:$apps_scale,dock_offset:$dock_offset,folder_offset:$folder_offset)
                                .animation(.easeInOut(duration:0.225).delay(home.movementDelays[node] ?? 0),value:home.layout.location(of:node))
                        }
                    }.compositingGroup()
                        .padding(UIScreen.main.bounds.width/(390/70)).drawingGroup()
                        .padding(-UIScreen.main.bounds.width/(390/70))
                }
            }.grayscale(show_multitasking ? 0.99:0).opacity(show_multitasking ? 0.3:1)
        }.background(GeometryReader { proxy in
            Color.clear.preference(key:HomeFramesKey.self,value:HomeFrames(dock:proxy.frame(in:.global)))
        })
    }
}

struct HomeDragImage: View {
    @EnvironmentObject private var home:HomeEditingController
    @Binding var current_view:String
    @Binding var apps_scale:CGFloat
    @Binding var dock_offset:CGFloat
    @Binding var folder_offset:CGFloat
    var body: some View {
        if let lift = home.lift ?? home.dropping {
            HomeFloatingIcon(lift:lift,position:home.dragPosition,current_view:$current_view,apps_scale:$apps_scale,dock_offset:$dock_offset)
        }
    }
}

private struct HomeFloatingClip:ViewModifier {
    let enabled:Bool
    func body(content:Content)->some View {
        if enabled {
            content.mask(alignment:.top) { Rectangle().frame(height:UIScreen.main.bounds.width/(390/60)) }
        } else { content }
    }
}

private struct HomeFloatingIcon:View {
    @EnvironmentObject private var home:HomeEditingController
    let lift:HomeLift
    @ObservedObject var position:HomeDragPosition
    @Binding var current_view:String
    @Binding var apps_scale:CGFloat
    @Binding var dock_offset:CGFloat
    private var grabbedAlpha:Double { if case .folder = lift.sourceContainer { return 0.5 }; return 0.75 }
    private var usesWallpaperShadow:Bool { home.lift?.node == lift.node || home.layout.location(of:lift.node)?.container != .dock }
    var body:some View {
            Group {
                if let id = lift.node.application {
                    if id == "Calendar" {
                        app_calendar(image_name:"Calendar",app_name:id,current_view:$current_view,apps_scale:$apps_scale,dock_offset:$dock_offset,folder_offset:.constant(0),canLaunch:false,shadowOverride:usesWallpaperShadow)
                    } else {
                        app(image_name:HomeApplication.named(id)?.image ?? id,app_name:id,current_view:$current_view,apps_scale:$apps_scale,dock_offset:$dock_offset,folder_offset:.constant(0),canLaunch:false,shadowOverride:usesWallpaperShadow)
                    }
                } else if let id = lift.node.folderID, let folder = home.layout.folders[id] {
                    HomeFolderIcon(folder:folder,shadow:usesWallpaperShadow,action:{})
                }
            }.transaction { $0.animation=nil }
                .frame(width:lift.cellSize.width,height:lift.cellSize.height)
                .background(alignment:.top) {
                    if home.dropping != nil && home.showsDockReflection(for:lift.node) {
                        HomeDockReflection(node:lift.node).transition(.identity)
                    }
                }
                .modifier(HomeFloatingClip(enabled:home.droppingIntoFolder != nil))
                .scaleEffect(home.lift == nil ? home.dropScale:1.25)
                .opacity(home.lift == nil ? 1:grabbedAlpha)
                .position(x:position.point.x+lift.grabOffset.width,y:position.point.y+lift.grabOffset.height)
                .allowsHitTesting(false)
    }
}
