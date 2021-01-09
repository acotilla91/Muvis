//
//  ActorDetailsViewController.swift
//  Muvis
//
//  Created by Alejandro Cotilla on 4/12/19.
//  Copyright © 2019 Carolco LLC. All rights reserved.
//

import UIKit
import Nuke

class ActorDetailsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    weak var actorItem: ActorItem!
    
    private var initialCollectionViewOffset: CGPoint!
    private var offsetAnimator: ACAnimator?

    @IBOutlet private var actorImageView: ShadowImageView!
    @IBOutlet private var actorNameLabel: UILabel!
    
    @IBOutlet private weak var collectionViewContainer: UIView!
    
    @IBOutlet private var collectionView: UICollectionView! {
        didSet {
            collectionView.delegate = self
            collectionView.dataSource = self

            collectionView.contentInsetAdjustmentBehavior = .never
            collectionView.showsVerticalScrollIndicator = false
            collectionView.clipsToBounds = false
            
            collectionView.register(UINib(nibName: MediaDescriptionCellView.typeName, bundle: nil), forCellWithReuseIdentifier: MediaDescriptionCellView.typeName)
            collectionView.register(UINib(nibName: PosterCellView.typeName, bundle: nil), forCellWithReuseIdentifier: PosterCellView.typeName)
            collectionView.register(UINib(nibName: MediaHeaderView.typeName, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: MediaHeaderView.typeName)
        }
    }
    
    private(set) var isContentReady: Bool = false {
        didSet {
            if isContentReady {
                collectionView.reloadData()
            }
        }
    }
    
    private var actorImageViewSize: CGSize = .zero {
        didSet {
            if !actorImageViewSize.equalTo(oldValue) {
                // Set actor image
                if let imageUrl = URL(string: actorItem.profilePath) {
                    ImagePipeline.shared.loadImage(with: imageUrl, progress: nil) { [weak self] (result) in
                        switch result {
                        case let .success(response):
                            guard let strongSelf = self else { return }
                            let image = response.image
                            let imageSize = strongSelf.actorImageViewSize
                            let scaledImage = image.scaled(to: imageSize, scalingMode: .aspectFill, horizontalAligment: .center, verticalAligment: .top)
                            let roundedImage = scaledImage.rounded()
                            
                            strongSelf.actorImageView.image = roundedImage
                        case .failure(_): break
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - UIViewController Overrides -

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide "Back" label
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        // Set actor name
        actorNameLabel.text = actorItem.name
        
        // Request full item details if necessary
        if actorItem.fullyDetailed {
            self.isContentReady = true
        }
        else {
            TMDbAPIService.shared.requestFullDetails(for: actorItem) { [weak self] in
                self?.isContentReady = true
            }
        }
        
        // Black status bar enforcing (needed for iOS 13+)
        navigationController?.navigationBar.barStyle = .default
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        
        navigationController?.navigationBar.tintColor = .black
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        actorImageViewSize = actorImageView.bounds.size
        updateCollectionViewInset()
    }
    
    // MARK: - UICollectionViewDelegate -

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard isContentReady else {
            return 0
        }

        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 1 {
            return actorItem.relatedMovies.count
        }

        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifierForCell(at: indexPath), for: indexPath)
        
        if let cell = cell as? MediaDescriptionCellView {
            cell.overviewLabel.text = actorItem.shortBiography
        }
        else if let cell = cell as? PosterCellView {
            let item = actorItem.relatedMovies[indexPath.item]
            if let imageUrl = URL(string: item.portraitPath) {
                Nuke.loadImage(
                    with: imageUrl,
                    options: ImageLoadingOptions(
                        transition: .fadeIn(duration: 0.3)
                    ),
                    into: cell.imageView
                )
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            if let movieDetailsViewController = UIStoryboard(name: "MovieDetails", bundle: nil).instantiateInitialViewController() as? MovieDetailsViewController {
                let movieItem = actorItem.relatedMovies[indexPath.item]
                movieDetailsViewController.mediaItem = movieItem
                navigationController?.pushViewController(movieDetailsViewController, animated: true)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch indexPath.section {
        case 0:
            let height = MediaDescriptionCellView.cellHeightForOverview(actorItem.shortBiography, width: collectionView.frame.width)
            return CGSize(width: collectionView.frame.width, height: height)
        case 1:
            return CGSize(width: 160, height: 240)
        default:
            assertionFailure("Wrong number of sections")
            return .zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 1 {
            return CGSize(width: collectionView.frame.width, height: 65)
        }
        
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if indexPath.section == 1 {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: MediaHeaderView.typeName, for: indexPath) as! MediaHeaderView
            headerView.label.text = "Known For"
            return headerView
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 1 {
            // Calculate the perfect spacing value to make the collection view cells layout more symmetrical
            let cellsWidth = self.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: IndexPath(item: 0, section: section)).width
            let cellsPerRow = CGFloat(numberOfCellsPerRow(forSectionAt: section))
            let remainderWidth = collectionView.frame.width - cellsWidth * cellsPerRow
            let spacing = remainderWidth / (cellsPerRow + 1)

            return UIEdgeInsets(top: 0, left: spacing, bottom: 30, right: spacing)
        }
        
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if section == 1 {
            return 40
        }
        
        return 0
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard initialCollectionViewOffset != nil else {
            initialCollectionViewOffset = scrollView.contentOffset
            return
        }
        
        // Stop the offset animation if the user starts dragging the collection view
        if collectionView.isTracking {
            offsetAnimator?.stop()
        }
        
        let delta = scrollView.contentOffset.y - initialCollectionViewOffset.y
        var displacement = abs(delta)
        if delta < 0 {
            // Move down the actor image view and name label as the user pulls down the scroll view
            actorImageView.transform = CGAffineTransform(translationX: 0, y: displacement)
            actorNameLabel.transform = CGAffineTransform(translationX: 0, y: displacement)
        }
        else if delta > 0 {
            // Zoom out the actor image view as the user pulls up the scroll view
            let maxHeight = actorImageView.bounds.height
            let minHeight = maxHeight * 0.4
            
            let maxDisplacement: CGFloat = maxHeight - minHeight
            if displacement > maxDisplacement { displacement = maxDisplacement }
            let newHeight = maxHeight - displacement
            let heightDelta = maxHeight - newHeight
            
            let scale = newHeight / maxHeight
            actorImageView.transform = CGAffineTransform(scaleX: scale, y: scale).concatenating(CGAffineTransform(translationX: 0, y: -heightDelta / 2))
            actorNameLabel.transform = CGAffineTransform(translationX: 0, y: -displacement)
        }
        else {
            actorImageView.transform = .identity
            actorNameLabel.transform = .identity
        }
        
        // Re-adjust the collection view insets now that the actor image view frame potentially changed
        if delta > 0 || delta == 0 {
            updateCollectionViewInset()
        }
    }
    
    // TODO: move to helper/extension to reuse from all view controllers that require this logic
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // Since the collection view content inset is modified during scrolling that breaks the deceleration animation.
        // That's why a simulated animation needs to be executed using `ACAnimator`.
        if velocity.y < 0.0 && scrollView.contentOffset.y == targetContentOffset.pointee.y {
            // Calculate the offset based on the velocity of the swipe
            var newYOffset = scrollView.contentOffset.y - (100 * abs(velocity.y))
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
                scrollView.contentOffset = CGPoint(x: 0, y: yOffset)
            })
            offsetAnimator?.start()
        }
    }
    
    // MARK: - Helpers -

    private func updateCollectionViewInset() {
        // Set the collection content inset based on the media actions view position
        collectionView.contentInset = UIEdgeInsets(top: actorNameLabel.frame.origin.y + actorNameLabel.frame.height + 10, left: 0, bottom: 20, right: 0)
        
        // Set the collection view mask so that the content goes behind every other screen element
        setupCollectionViewMaskingGradient()
    }
    
    // TODO: move to helper/extension to reuse from all view controllers that require this logic
    private func setupCollectionViewMaskingGradient() {
        let gradientHeight: CGFloat = 20.0
        let gradientEndLocation = NSNumber(value: Float(gradientHeight / UIScreen.main.bounds.height))
        
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        gradient.locations = [0, gradientEndLocation]
        gradient.frame = CGRect(x: 0, y: collectionView.contentInset.top, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        collectionViewContainer.layer.mask = gradient
    }
    
    private func reuseIdentifierForCell(at indexPath: IndexPath) -> String {
        switch indexPath.section {
        case 0:
            return MediaDescriptionCellView.typeName
        case 1:
            return PosterCellView.typeName
        default:
            assertionFailure("Wrong number of sections")
            return ""
        }
    }
    
    func numberOfCellsPerRow(forSectionAt section: Int) -> Int {
        let cellsWidth = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: IndexPath(item: 0, section: section)).width
        var cellsPerRow = floor(collectionView.frame.width / cellsWidth)
        let interitemSpacing = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing
        while cellsWidth * cellsPerRow + cellsPerRow * (interitemSpacing - 1) > collectionView.frame.width {
            cellsPerRow -= 1
        }
        
        return Int(cellsPerRow)
    }
}
