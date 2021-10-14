//
//  TimelineViewController.swift
//  TimelineViewController
//
//  Copyright (c) 2021 Changbeom Ahn
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit
import Combine
import Kingfisher
import AVFoundation
import SwiftUI
import InstagramPrivateAPI

class HeaderView: UICollectionReusableView {
    let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MediaCell: UICollectionViewCell {
    var media: Media? {
        didSet {
//            print(#function, media?.url.path ?? "no url?")
            guard let type = media?.type else {
                fatalError()
//                return
            }

            switch type {
            case .image:
                imageView.kf.setImage(with: media?.url)
            case .video:
                playerView.player = AVPlayer(url: media!.url)
//                observation = playerView.player?.observe(\.currentItem?.status, options: [.old, .new]) { player, change in
//                    print(change, self.media!.url.path)
//                }
                playerView.player?.play()
            case .carousel:
                fatalError()
            }
            
            playerView.isHidden = type != .video
        }
    }
    
    var observation: NSKeyValueObservation?
    
    let imageView = UIImageView()
   
    lazy var playerView: PlayerView = {
        let view = PlayerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    
    var player: AVPlayer? {
        get { playerLayer?.player }
        set { playerLayer?.player = newValue }
    }
    
    var playerLayer: AVPlayerLayer? { layer as? AVPlayerLayer }
}

class FooterView: UICollectionReusableView {
    let moreView = MoreView()
    
    lazy var vStack = UIStackView(arrangedSubviews: [moreView])
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        moreView.translatesAutoresizingMaskIntoConstraints = false
        
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.axis = .vertical
        addSubview(vStack)
        
        NSLayoutConstraint.activate([
            vStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            vStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            vStack.topAnchor.constraint(equalTo: topAnchor),
            vStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol MoreViewDelegate {
    var isExpanded: Bool { get set }
}

class MoreView: UIView {
    let textView = UITextView()
    
    lazy var buttonBottomConstraint = button.bottomAnchor.constraint(equalTo: bottomAnchor)
    
    lazy var bottomConstraint = textView.bottomAnchor.constraint(equalTo: bottomAnchor)
    
    lazy var baselineConstraint = button.firstBaselineAnchor.constraint(equalTo: textView.firstBaselineAnchor)
    
    let button = UIButton()
    
    fileprivate func updateUI() {
        button.isHidden = isShowingAll
        
        if isShowingAll {
            buttonBottomConstraint.isActive = false
            bottomConstraint.isActive = true
        } else {
            bottomConstraint.isActive = false
            buttonBottomConstraint.isActive = true
        }
    }
    
    var isShowingAll: Bool {
        (delegate?.isExpanded ?? false)
    }
    
    var lineCount: CGFloat { textView.contentSize != .zero ? textView.contentSize.height / font.lineHeight : 99}
    
    var font: UIFont { UIFont.preferredFont(forTextStyle: .body) }
    
    var delegate: MoreViewDelegate? {
        didSet {
            let glyphCount = textView.layoutManager.numberOfGlyphs
            var index = 0
            var lineRange = NSRange()
            var lineCount = 0
            while index < glyphCount {
                textView.layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
                index = NSMaxRange(lineRange)
                lineCount += 1
            }
            print(textView.contentSize, lineCount)
            updateUI()
        }
    }
    
    var section: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        clipsToBounds = true
        
        textView.font = font
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.topAnchor.constraint(equalTo: topAnchor),
        ])
        
        button.setTitle("more", for: .normal)
//        button.backgroundColor = .systemBackground
        let layer = button.layer
        layer.shadowOpacity = 1
        layer.shadowOffset = CGSize(width: -8, height: 0)
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        button.addTarget(self, action: #selector(toggle(_:)), for: .touchUpInside)
        
        updateUI()
        
        baselineConstraint.constant = textView.font!.lineHeight
        
        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            baselineConstraint,
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func toggle(_ sender: UIButton) {
        delegate?.isExpanded.toggle()
        updateUI()
        NotificationCenter.default.post(name: .invalidatedLayout, object: self)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard var delegate = delegate, !delegate.isExpanded && lineCount < 3 else {
            return
        }
        delegate.isExpanded.toggle()
        
        updateUI()
    }
}

extension Notification.Name {
    static let invalidatedLayout = Notification.Name("io.github.kewlbear.inssagram.invalidatedLayout")
}

class TimelineViewController: UIViewController {

    var collectionView: UICollectionView?
    
    typealias DataSource = UICollectionViewDiffableDataSource<String, String>
    
    var dataSource: DataSource?
    
    var service: AppModel!
    
    var subscriptions = Set<AnyCancellable>()
    
    var notificationObserver: NSObjectProtocol?
    
    var hiddenHashtagsRevision = 0
    
    deinit {
        print(#function)
    }
    
    func dismantle() {
        for subscription in subscriptions {
            subscription.cancel()
        }
        
        notificationObserver.map { NotificationCenter.default.removeObserver($0) }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureHierarchy()
        configureDataSource()
    }
        
    func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment in
            let post = self.service.filtered[sectionIndex]
            let ratio = post.carousel_media?.map(\.aspectRatio).min() ?? post.aspectRatio
            let heightDimension: NSCollectionLayoutDimension = .fractionalWidth(1 / ratio)
            let layoutSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: heightDimension)
            let item = NSCollectionLayoutItem(layoutSize: layoutSize)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: layoutSize, subitem: item, count: 1)
            
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .paging
            
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(44))
            let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(UIFont.preferredFont(forTextStyle: .body).lineHeight * 2))
            section.boundarySupplementaryItems = [
                NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top),
                NSCollectionLayoutBoundarySupplementaryItem(layoutSize: footerSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom),
            ]
            
            return section
        }
        
        return layout
    }
        
    func configureHierarchy() {
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.frame = view.bounds
        view.addSubview(collectionView)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        self.collectionView = collectionView
    }

    func configureDataSource() {
        guard let collectionView = collectionView else {
            fatalError()
        }

        let mediaCell = UICollectionView.CellRegistration<MediaCell, Media> { cell, indexPath, media in
            cell.media = media
        }
        
        let dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            let post = self.service.filtered[indexPath.section]
            let media: Media = post.carousel_media?[indexPath.item] ?? post
            let cell = collectionView.dequeueConfiguredReusableCell(using: mediaCell, for: indexPath, item: media)
            
            if indexPath.section == self.service.filtered.count - 1 {
                self.service.loadNext()
            }
            
            return cell
        }
        
        let header = UICollectionView.SupplementaryRegistration<HeaderView>(elementKind: UICollectionView.elementKindSectionHeader) { supplementaryView, elementKind, indexPath in
            supplementaryView.label.text = self.service.filtered[indexPath.section].user.username
        }
        
        let footer = UICollectionView.SupplementaryRegistration<FooterView>(elementKind: UICollectionView.elementKindSectionFooter) { supplementaryView, elementKind, indexPath in
            let post = self.service.filtered[indexPath.section]
            
            func makeAttributedString(_ text: String) -> NSAttributedString {
                let string = NSMutableAttributedString(string: text, attributes:
                                                        [.font: UIFont.preferredFont(forTextStyle: .body),
                                                         .foregroundColor: UIColor.label])
                let url = URL(string: scheme + ":")!
                for range in text.hashTagRanges() {
                    string.addAttribute(.link, value: url, range: NSRange(range, in: text))
                }
                return string
            }
            
            supplementaryView.moreView.textView.attributedText = post.caption.map { makeAttributedString($0.text) }
            
            struct Delegate: MoreViewDelegate {
                let post: Post
                
                let service: AppModel
                
                var isExpanded: Bool {
                    get { service.expandedPosts.contains(post.id) }
                    set {
                        if newValue {
                            service.expandedPosts.insert(post.id)
                        } else {
                            service.expandedPosts.remove(post.id)
                        }
                    }
                }
            }
            
            supplementaryView.moreView.delegate = Delegate(post: post, service: self.service)
            supplementaryView.moreView.section = post.id
            supplementaryView.moreView.textView.delegate = self
        }
        
        dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
            switch elementKind {
            case UICollectionView.elementKindSectionHeader:
                return collectionView.dequeueConfiguredReusableSupplementary(using: header, for: indexPath)
            case UICollectionView.elementKindSectionFooter:
                return collectionView.dequeueConfiguredReusableSupplementary(using: footer, for: indexPath)
            default: fatalError()
            }
        }
        
        self.dataSource = dataSource
        
        service.$filtered
            .receive(on: RunLoop.main)
            .sink { posts in
                var snapshot = dataSource.snapshot()
                if self.hiddenHashtagsRevision != self.service.hiddenHashtagsRevision {
                    snapshot.deleteAllItems()
                    self.hiddenHashtagsRevision = self.service.hiddenHashtagsRevision
                }
                let startIndex = snapshot.sectionIdentifiers.count
                for index in startIndex..<posts.count {
                    let post = posts[index]
                    print("ds", index, post.id, post.user.username, post.type!)
                    snapshot.appendSections([post.id])
                    let count = post.carousel_media_count ?? 1
                    snapshot.appendItems((0..<count).map { "\(post.id).\($0)"}, toSection: nil)
                }
                DispatchQueue.main.async {
                    dataSource.apply(snapshot)
                }
            }
            .store(in: &subscriptions)
        
        notificationObserver = NotificationCenter.default.addObserver(forName: .invalidatedLayout, object: nil, queue: .main) { notification in
            guard let section = (notification.object as? MoreView)?.section else {
                collectionView.collectionViewLayout.invalidateLayout()
                return
            }
            var snapshot = dataSource.snapshot()
            snapshot.reloadSections([section])
            dataSource.apply(snapshot)
        }
    }
   
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension TimelineViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard URL.scheme == scheme else { return true }
        let text = textView.text as String
        let hashTag = text[Range(characterRange, in: text)!]
        let alert = UIAlertController(title: nil, message: "Hide \(hashTag)?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Hide", style: .default) { _ in
            var snapshot = self.dataSource!.snapshot()
            snapshot.deleteAllItems()
            self.dataSource?.apply(snapshot)
            
            guard let hashtags = self.service.hiddenHashtags else {
                self.service.hiddenHashtags = String(hashTag.dropFirst())
                return
            }
            self.service.hiddenHashtags = hashtags + hashTag
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true, completion: nil)
        return false
    }
}

extension TimelineViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(#function, indexPath)
    }
}
