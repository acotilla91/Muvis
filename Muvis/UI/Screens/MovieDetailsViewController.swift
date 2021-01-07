//
//  MovieDetailsViewController.swift
//  Muvis
//
//  Created by Alejandro Cotilla on 2/19/19.
//  Copyright © 2019 Carolco LLC. All rights reserved.
//

import UIKit

import Nuke
import UICircularProgressRing
import ACAnimator

class MovieDetailsViewController: UIViewController, MultiCollectionViewDelegate, MediaActionsViewDelegate {

    weak var mediaItem: MediaItem!

    private var initialCollectionViewOffset: CGPoint!
    private var offsetAnimator: ACAnimator?

    @IBOutlet private weak var topGradientView: GradientView!
    @IBOutlet private weak var heroImageView: ShadowImageView!
    
    @IBOutlet private weak var collectionView: MultiCollectionView! {
        didSet {
            collectionView.delegate = self
            
            collectionView.contentInsetAdjustmentBehavior = .never

            collectionView.register(UINib(nibName: MovieMetadataCellView.typeName, bundle: nil), forCellWithReuseIdentifier: MovieMetadataCellView.typeName)
            collectionView.register(UINib(nibName: MediaDescriptionCellView.typeName, bundle: nil), forCellWithReuseIdentifier: MediaDescriptionCellView.typeName)
            collectionView.register(UINib(nibName: ClipCellView.typeName, bundle: nil), forCellWithReuseIdentifier: ClipCellView.typeName)
            collectionView.register(UINib(nibName: CircularCellView.typeName, bundle: nil), forCellWithReuseIdentifier: CircularCellView.typeName)
            collectionView.register(UINib(nibName: PosterCellView.typeName, bundle: nil), forCellWithReuseIdentifier: PosterCellView.typeName)
            collectionView.register(UINib(nibName: MediaHeaderView.typeName, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: MediaHeaderView.typeName)
        }
    }
    
    private var mediaActionsView: MediaActionsView!
    
    private(set) var isContentReady: Bool = false {
        didSet {
            if isContentReady {
                collectionView.reloadData()
            }
        }
    }
    
    private var clipsSection: Int {
        guard mediaItem.clips.count > 0 else {
            return -1
        }
        
        return 2
    }
    
    private var actorsSection: Int {
        guard mediaItem.actors.count > 0 else {
            return -1
        }
        
        if mediaItem.clips.count > 0 {
            return 3
        }
        
        return 2
    }
    
    private var recommendationsSection: Int {
        guard mediaItem.relatedMovies.count > 0 else {
            return -1
        }
        
        if mediaItem.clips.count > 0 && mediaItem.actors.count > 0 {
            return 4
        }
        else if mediaItem.clips.count > 0 || mediaItem.actors.count > 0 {
            return 3
        }
        
        return 2
    }
    
    // MARK: - UIViewController Overrides -
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide "Back" label
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        // Add user score view to the hero image
        addUserScoreView()
        
        // Set hero image
        if let imageUrl = URL(string: mediaItem.backdropPath) {
            ImagePipeline.shared.loadImage(with: imageUrl, progress: nil) { [weak self] (result) in
                switch result {
                case let .success(response):
                    guard let strongSelf = self else { return }
                    let image = response.image
                    let maskSize = CGSize(width: image.size.width, height: image.size.height)
                    let path = strongSelf.bottomCurvedMask(for: maskSize, curvature: 0.15)
                    let newImage = image.masked(with: path)
                    strongSelf.heroImageView.image = newImage
                case .failure(_): break
                }
            }
        }
        
        // Add media actions view
        addMediaActionsView()
        
        // Request full item details if necessary
        if mediaItem.fullyDetailed {
            self.isContentReady = true
        }
        else {
            TMDbAPIService.shared.requestFullDetails(for: mediaItem) { [weak self] in
                self?.isContentReady = true
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        
        navigationController?.navigationBar.tintColor = .white
        
        setNeedsStatusBarAppearanceUpdate()
        
        // White status bar enforcing (needed for iOS 13+)
        navigationController?.navigationBar.barStyle = .black
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateMediaActionsViewFrame()
        updateCollectionViewInset()
    }
    
    // MARK: - UI Building Blocks -

    private func addUserScoreView() {
        let userScoreView = UICircularProgressRing()
        userScoreView.innerRingWidth = 3
        userScoreView.outerRingWidth = 0
        userScoreView.fontColor = .white
        userScoreView.font = userScoreView.font.withSize(13)
        userScoreView.shouldShowValueText = true
        userScoreView.startAngle = 270
        userScoreView.valueKnobStyle = UICircularRingValueKnobStyle(size: 0, color: .clear)

        // Set background color to help with visibility
        let size: CGFloat = 44.0
        userScoreView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        userScoreView.layer.masksToBounds = true
        userScoreView.layer.cornerRadius = size / 2.0
        
        // Setup constraints
        let userScoreViewItem = UIBarButtonItem(customView: userScoreView)
        userScoreViewItem.customView?.widthAnchor.constraint(equalToConstant: size).isActive = true
        userScoreViewItem.customView?.heightAnchor.constraint(equalToConstant: size).isActive = true
        
        // Description label
        let label = UILabel()
        label.text = "Score"
        label.textColor = .white
        
        // Set user score elements on the navigation bar
        self.navigationItem.rightBarButtonItems = [userScoreViewItem, UIBarButtonItem(customView: label)]

        // Animate to score value
        userScoreView.animateToValue(CGFloat(mediaItem.userScore * 10.0))
    }
    
    private func addMediaActionsView() {
        mediaActionsView = MediaActionsView.fromNib()
        view.addSubview(mediaActionsView)
        
        mediaActionsView.delegate = self
        mediaActionsView.titleLabel.text = mediaItem.title.uppercased()
        
        // Set play button color based on the media image
        mediaItem.averageColor(of: .backdrop, completion: { [weak self] (color) in
            if let color = color {
                self?.mediaActionsView.playImageView.tintColor = color
            }
        })
    }
    
    // MARK: - MultiCollectionViewDelegate -
    
    func numberOfSections(in collectionView: MultiCollectionView) -> Int {
        guard isContentReady else {
            return 2
        }
        
        var count = 2
        if mediaItem.clips.count > 0 { count += 1 }
        if mediaItem.actors.count > 0 { count += 1 }
        if mediaItem.relatedMovies.count > 0 { count += 1 }
        
        return count
    }
    
    func collectionView(_ collectionView: MultiCollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case clipsSection:
            return mediaItem.clips.count
        case actorsSection:
            return mediaItem.actors.count
        case recommendationsSection:
            return mediaItem.relatedMovies.count
        default:
            return 1
        }
    }
    
    func collectionView(_ collectionView: MultiCollectionView, reuseIdentifierForCellAt indexPath: IndexPath) -> String {
        switch indexPath.section {
        case 0:
            return MovieMetadataCellView.typeName
        case 1:
            return MediaDescriptionCellView.typeName
        case clipsSection:
            return ClipCellView.typeName
        case actorsSection:
            return CircularCellView.typeName
        case recommendationsSection:
            return PosterCellView.typeName
        default:
            assertionFailure("Wrong number of sections")
            return ""
        }
    }
    
    func collectionView(_ collectionView: MultiCollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let movieMetadataCell = cell as? MovieMetadataCellView {
            movieMetadataCell.yearLabel.text = "\(mediaItem.releaseDate.year)"
            movieMetadataCell.genresLabel.text = mediaItem.genres.joined(separator: ", ")
            movieMetadataCell.contentRatingLabel.text = mediaItem.contentRating.isEmpty ? "-" : mediaItem.contentRating
            movieMetadataCell.revenueLabel.text = mediaItem.revenue > 0 ? "$\(Double(mediaItem.revenue).formatPoints())" : "-"
        }
        else if let mediaDescriptionCell = cell as? MediaDescriptionCellView {
            mediaDescriptionCell.overviewLabel.text = mediaItem.shortOverview
        }
        else if let clipCellView = cell as? ClipCellView {
            let ytItem = mediaItem.clips[indexPath.item]
            clipCellView.titleLabel.text = ytItem.title
            loadClipImage(into: clipCellView.imageView, from: ytItem)
        }
        else if let circularCellView = cell as? CircularCellView {
            let actorItem = mediaItem.actors[indexPath.item]
            circularCellView.titleLabel.text = actorItem.name
            
            if let imageUrl = URL(string: actorItem.profilePath) {
                // TODO: Set placeholder image temporarly while the other image is being requested
                ImagePipeline.shared.loadImage(with: imageUrl, progress: nil) { [weak self] (result) in
                    guard let strongSelf = self else {
                        return
                    }
                    
                    switch result {
                    case let .success(response):
                        let image = response.image
                        let cellSize = strongSelf.collectionView(collectionView, sizeForItemAt: indexPath)
                        let imageWidth = cellSize.width - CircularCellView.imageHorizontalPadding * 2
                        let imageSize = CGSize(width: imageWidth, height: imageWidth)
                        let scaledImage = image.scaled(to: imageSize, scalingMode: .aspectFill, horizontalAligment: .center, verticalAligment: .top)
                        let roundedImage = scaledImage.rounded()
                        circularCellView.imageView.image = roundedImage
                    case .failure(_): break
                    }
                }
            }
        }
        else if let posterCellView = cell as? PosterCellView {
            let item = mediaItem.relatedMovies[indexPath.item]
            if let imageUrl = URL(string: item.portraitPath) {
                Nuke.loadImage(
                    with: imageUrl,
                    options: ImageLoadingOptions(
                        transition: .fadeIn(duration: 0.3)
                    ),
                    into: posterCellView.imageView
                )
            }
        }
    }
    
    func collectionView(_ collectionView: MultiCollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.section {
        case clipsSection:
            let clipItem = mediaItem.clips[indexPath.item]
            PlaybackCoordinator.shared.attemptPlayback(for: clipItem)
        case actorsSection:
            if let actorDetailsViewController = UIStoryboard(name: "ActorDetails", bundle: nil).instantiateInitialViewController() as? ActorDetailsViewController {
                let actorItem = mediaItem.actors[indexPath.item]
                actorDetailsViewController.actorItem = actorItem
                navigationController?.pushViewController(actorDetailsViewController, animated: true)
            }
            break
        case recommendationsSection:
            if let movieDetailsViewController = UIStoryboard(name: "MovieDetails", bundle: nil).instantiateInitialViewController() as? MovieDetailsViewController {
                let recommendedItem = mediaItem.relatedMovies[indexPath.item]
                movieDetailsViewController.mediaItem = recommendedItem
                navigationController?.pushViewController(movieDetailsViewController, animated: true)
            }
        default:
            break
        }
    }
    
    func collectionView(_ collectionView: MultiCollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch indexPath.section {
        case 0:
            return CGSize(width: collectionView.frame.width, height: 108)
        case 1:
            let height = MediaDescriptionCellView.cellHeightForOverview(mediaItem.shortOverview, width: collectionView.frame.width)
            return CGSize(width: collectionView.frame.width, height: height)
        case clipsSection:
            return CGSize(width: 232, height: 228)
        case actorsSection:
            return CGSize(width: 156, height: 184)
        case recommendationsSection:
            return CGSize(width: 160, height: 240)
        default:
            assertionFailure("Wrong number of sections")
            return .zero
        }
    }

    func collectionView(_ collectionView: MultiCollectionView, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch section {
        case clipsSection, actorsSection, recommendationsSection:
            return CGSize(width: collectionView.frame.width, height: 65)
        default:
            return .zero
        }
    }
    
    func collectionView(_ collectionView: MultiCollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch indexPath.section {
        case clipsSection, actorsSection, recommendationsSection:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: MediaHeaderView.typeName, for: indexPath) as! MediaHeaderView
            headerView.label.text = headerTitle(for: indexPath.section)
            return headerView
        default:
            return UICollectionReusableView()
        }
    }
    
    func collectionView(_ collectionView: MultiCollectionView, insetForSectionAt section: Int) -> UIEdgeInsets {
        switch section {
        case clipsSection, actorsSection:
            return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        case recommendationsSection:
            return UIEdgeInsets(top: 0, left: 20, bottom: 30, right: 20)
        default:
            return .zero
        }
    }
    
    func collectionView(_ collectionView: MultiCollectionView, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        switch section {
        case clipsSection:
            return 25
        case actorsSection:
            return 5
        case recommendationsSection:
            return 20
        default:
            return 0
        }
    }
    
    func collectionViewDidScrollVertically(_ collectionView: MultiCollectionView, toOffset offset: CGPoint) {
        guard initialCollectionViewOffset != nil else {
            initialCollectionViewOffset = offset
            return
        }
        
        // Stop the offset animation if the user starts dragging the collection view
        if collectionView.isTracking {
            offsetAnimator?.stop()
        }

        let delta = offset.y - initialCollectionViewOffset.y
        let displacement = abs(delta)
        if delta < 0 {
            // Zoom in the hero image view as the user pulls down the scroll view
            let initialHeroImageHeight = heroImageReach(for: heroImageView.bounds)
            let initialHeroImageWidth = initialHeroImageHeight * 16 / 9
            
            let heroImageContainerHeightDelta = initialHeroImageHeight - heroImageView.bounds.height
            let heroImageContainerWidthDelta = initialHeroImageWidth - heroImageView.bounds.width
            
            let newHeroImageHeight = initialHeroImageHeight + displacement * 2
            let newHeroImageWidth = newHeroImageHeight * 16 / 9
            
            let heroImageContainerHeight = newHeroImageHeight - heroImageContainerHeightDelta
            let heroImageContainerWidth = newHeroImageWidth - heroImageContainerWidthDelta
            
            let scale = min(heroImageContainerWidth / heroImageView.bounds.width, heroImageContainerHeight / heroImageView.bounds.height)

            heroImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
            heroImageView.imageView.alpha = 1.0
        }
        else if delta > 0 {
            // Move up the hero image view as the user pulls up the scroll view
            let minHeroImageReach: CGFloat = 100.0
            let initialHeroImageReach = heroImageReach(for: heroImageView.bounds)
            
            let maxDisplacement: CGFloat = initialHeroImageReach - minHeroImageReach
            let translationY = displacement < maxDisplacement ? -displacement : -maxDisplacement
            heroImageView.transform = CGAffineTransform(translationX: 0, y: translationY)
            
            // Make the hero image appear blurred as the user scrolls up
            let alpha = 1.0 - displacement / maxDisplacement
            heroImageView.imageView.alpha = alpha
        }
        else {
            heroImageView.transform = .identity
            heroImageView.imageView.alpha = 1.0
        }
        
        // Re-adjust the media actions view layout and the collection view insets now that the hero image view frame potentially changed
        updateMediaActionsViewFrame()
        if delta > 0 || delta == 0 {
            updateCollectionViewInset()
        }
    }
    
    func collectionViewWillEndDraggingVertically(_ collectionView: MultiCollectionView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // Since the collection view content inset is modified during scrolling that breaks the deceleration animation.
        // That's why a simulated animation needs to be executed using `ACAnimator`.
        if velocity.y < 0.0 && collectionView.contentOffset.y == targetContentOffset.pointee.y {
            // Calculate the offset based on the velocity of the swipe
            var newYOffset = collectionView.contentOffset.y - (100 * abs(velocity.y))
            if newYOffset < initialCollectionViewOffset.y {
              newYOffset = initialCollectionViewOffset.y
            }

            // Determine the displacement needed to get to the targeted offset
            let initialYOffset = collectionView.contentOffset.y
            let displacement = newYOffset - initialYOffset
            
            // Calculate the animation duration using the kinematic equation
            // https://www.physicsclassroom.com/class/1DKin/Lesson-6/Kinematic-Equations
            let pointsPerSecond: CGFloat = 400.0
            var duration: CGFloat = (abs(displacement) * 2.0) / pointsPerSecond
            if duration > 0.8 { duration = 0.8 } // Cap the duration at 0.8s
            
            // Start animation
            offsetAnimator = ACAnimator(duration: CFTimeInterval(duration), easeFunction: .cubicOut, animation: { (fraction, _, _) in
                let yOffset = initialYOffset + displacement * CGFloat(fraction)
                collectionView.contentOffset = CGPoint(x: 0, y: yOffset)
            })
            offsetAnimator?.start()
        }
    }
    
    // MARK: - MediaActionsViewDelegate -
    
    func actionsViewDidSelectPlayButton(_ actionsView: MediaActionsView) {
        PlaybackCoordinator.shared.attemptPlayback(for: mediaItem)
    }
    
    func actionsViewDidSelectAddButton(_ actionsView: MediaActionsView) {
        // TODO: actionsViewDidSelectAddButton
    }
    
    func actionsViewDidSelectDownloadButton(_ actionsView: MediaActionsView) {
        // TODO: actionsViewDidSelectDownloadButton
    }
    
    // MARK: - Helpers -
    
    private func heroImageReach(for containerFrame: CGRect? = nil) -> CGFloat {
        // Determine hero image size after being scaled to fill
        let imageAreaSize = containerFrame?.size ?? heroImageView.frame.size
        let imageAspectRatio = CGSize(width: 16.0, height: 9.0)
        let scale = max(imageAreaSize.width / imageAspectRatio.width, imageAreaSize.height / imageAspectRatio.height)
        let imageExpandedSize = imageAspectRatio.scaled(by: scale)
        let imageHeightGrowth = imageExpandedSize.height - imageAreaSize.height
        let imageOrigin = containerFrame?.origin ?? heroImageView.frame.origin
        let imageReach = imageAreaSize.height + imageHeightGrowth / 2.0 + imageOrigin.y
        return imageReach
    }
    
    private func updateMediaActionsViewFrame() {
        let actionsViewY = heroImageReach() - MediaActionsView.playButtonSize / 2.0
        let actionsViewPosition = CGPoint(x: 0, y: actionsViewY)
        let actionsViewHeight = MediaActionsView.cellHeightForTitle(mediaItem.title.uppercased(), width: collectionView.frame.width)
        let actionsViewSize = CGSize(width: collectionView.frame.width, height: actionsViewHeight)
        mediaActionsView.frame = CGRect(origin: actionsViewPosition, size: actionsViewSize)
    }
    
    private func bottomCurvedMask(for size: CGSize, curvature: CGFloat) -> UIBezierPath {
        let bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let w = bounds.size.width
        let h = bounds.size.height
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w, y: h - (h * curvature)))
        
        // Draw quadratic curve.
        // Calculate the control point based on the 3 points that the curve must pass through.
        // Based on: https://stackoverflow.com/a/38753266/1792699
        func controlPoint(_ leftPoint: CGPoint, _ rightPoint: CGPoint, _ middlePoint: CGPoint) -> CGPoint {
            let x = 2 * middlePoint.x - leftPoint.x / 2 - rightPoint.x / 2
            let y = 2 * middlePoint.y - leftPoint.y / 2 - rightPoint.y / 2
            return CGPoint(x: x, y: y)
        }
        
        let leftPoint = CGPoint(x: 0, y: h - (h * curvature))
        let middlePoint = CGPoint(x: w / 2, y: h)
        let rightPoint = CGPoint(x: w, y: h - (h * curvature))
        
        path.addQuadCurve(to: leftPoint, controlPoint: controlPoint(leftPoint, rightPoint, middlePoint))
        
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.close()
        
        return path
    }
    
    private func loadClipImage(into imageView: ImageDisplayingView, from youtubeItem: YouTubeItem) {
        guard
            let imageUrlHigh = URL(string: youtubeItem.thumbnailPathHigh),
            let imageUrlMedium = URL(string: youtubeItem.thumbnailPathMedium)
            else {
                return
        }
        
        var imageRequest = ImageRequest(url: imageUrlHigh)
        imageRequest.priority = .high
        
        var imageLoadingOptions = ImageLoadingOptions.shared
        imageLoadingOptions.transition = .fadeIn(duration: 0.3)
        
        Nuke.loadImage(with: imageRequest, options: imageLoadingOptions, into: imageView, progress: nil) { (result) in
            switch result {
            case .failure(_):
                // Use medium quality image if high quality image is not available
                Nuke.loadImage(with: ImageRequest(url: imageUrlMedium), options: imageLoadingOptions, into: imageView, progress: nil)
            case .success(_): break
            }
        }
    }
    
    private func updateCollectionViewInset() {
        // Set the collection content inset based on the media actions view position
        collectionView.contentInset = UIEdgeInsets(top: mediaActionsView.frame.origin.y + mediaActionsView.frame.height, left: 0, bottom: 20, right: 0)
        
        // Set the collection view mask so that the content goes behind every other screen element
        setupCollectionViewMaskingGradient()
    }
    
    private func setupCollectionViewMaskingGradient() {
        let gradientHeight: CGFloat = 20.0
        let gradientEndLocation = NSNumber(value: Float(gradientHeight / UIScreen.main.bounds.height))

        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        gradient.locations = [0, gradientEndLocation]
        gradient.frame = CGRect(x: 0, y: collectionView.contentInset.top, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        collectionView.layer.mask = gradient
    }
    
    private func headerTitle(for section: Int) -> String {
        switch section {
        case clipsSection:
            return "Clips & Trailers"
        case actorsSection:
            return "Cast"
        case recommendationsSection:
            return "You Might Also Like"
        default:
            return ""
        }
    }
}
