//
//  HomeViewController.swift
//  Muvis
//
//  Created by Alejandro Cotilla on 9/5/20.
//  Copyright © 2020 Carolco LLC. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import Nuke

class HomeViewController: UIViewController, MultiCollectionViewDelegate, ACPaginationViewDelegate {
    
    private var activityIndicator: NVActivityIndicatorView!
    
    private var mediaCategories: [MediaCategory] = []
    
    let posterCellViewId = PosterCellView.typeName
    let featuredCellViewId = FeaturedCellView.typeName
    let mediaHeaderViewId = MediaHeaderView.typeName
    let paginationFooterViewId = PaginationFooterView.typeName
    
    @IBOutlet weak var collectionView: MultiCollectionView! {
        didSet {
            collectionView.delegate = self
            
            collectionView.register(UINib(nibName: posterCellViewId, bundle: nil), forCellWithReuseIdentifier: posterCellViewId)
            collectionView.register(UINib(nibName: featuredCellViewId, bundle: nil), forCellWithReuseIdentifier: featuredCellViewId)
            collectionView.register(UINib(nibName: mediaHeaderViewId, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: mediaHeaderViewId)
            collectionView.register(PaginationFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: paginationFooterViewId)
        }
    }
    
    // MARK: - Screen Preferences -
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    // MARK: - UI Setup -

    func setupActivityIndicator() {
        let indicatorSize: CGFloat = 60.0
        let indicatorOrigin = CGPoint(x: UIScreen.main.bounds.width/2 - indicatorSize/2, y: UIScreen.main.bounds.height/2 - indicatorSize/2)
        let indicatorFrame = CGRect(x: indicatorOrigin.x, y: indicatorOrigin.y, width: indicatorSize, height: indicatorSize)
        activityIndicator = NVActivityIndicatorView(frame: indicatorFrame, type: .circleStrokeSpin, color: UIColor(hex: "#434446"), padding: 8.0)
        view.addSubview(activityIndicator)
    }
    
    private func setupCollectionViewMaskingGradient() {
        let safeAreaTop = view.safeAreaInsets.top
        let gradientHeight: CGFloat = safeAreaTop + 10.0
        let gradientEndLocation = NSNumber(value: Float(gradientHeight / UIScreen.main.bounds.height))
     
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        gradient.locations = [0, gradientEndLocation]
        gradient.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        collectionView.layer.mask = gradient
    }

    // MARK: - View Cycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide "Back" label
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        setupActivityIndicator()
        loadContent()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        setupCollectionViewMaskingGradient()
    }
    
    // MARK: - Navigation -

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard
            let movieDetailsVC = segue.destination as? MovieDetailsViewController,
            let selectedIndexPath = collectionView.indexPathsForSelectedItems?[0]
            else {
                return
        }
        
        let mediaItem = mediaCategories[selectedIndexPath.section].items[selectedIndexPath.item]
        movieDetailsVC.mediaItem = mediaItem
    }
    
    // MARK: - UI Accessors -

    private(set) var focusedFeaturedItemIndex: Int! {
        didSet {
            guard
                focusedFeaturedItemIndex != oldValue,
                let paginationFooterView = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: 0) as? PaginationFooterView
                else {
                return
            }
            
            // Update the indicator index
            paginationFooterView.paginationView.selectedIndex = focusedFeaturedItemIndex

            // Update the indicator color based on the focused featured cell
            let mediaItem = mediaCategories[0].items[focusedFeaturedItemIndex]
            mediaItem.averageColor(of: .backdrop) { (color) in
                if let color = color {
                    paginationFooterView.paginationView.elasticMarker.backgroundColor = color
                }
            }
        }
    }
    
    // MARK: - API Communication -

    private func loadContent() {
        activityIndicator.startAnimating()
        
        TMDbAPIService.shared.requestMediaCategories { (categories) in
            self.mediaCategories = categories
            self.collectionView.reloadData()
            self.activityIndicator.stopAnimating()
        }
    }
    
    // MARK: - MultiCollectionView Delegate -
    
    func numberOfSections(in collectionView: MultiCollectionView) -> Int {
        return mediaCategories.count
    }
    
    func collectionView(_ collectionView: MultiCollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaCategories[section].items.count
    }
    
    func collectionView(_ collectionView: MultiCollectionView, reuseIdentifierForCellAt indexPath: IndexPath) -> String {
        return indexPath.section == 0 ? featuredCellViewId : posterCellViewId
    }
    
    func collectionView(_ collectionView: MultiCollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let mediaItem = mediaCategories[indexPath.section].items[indexPath.item]

        let imagePath = indexPath.section == 0 ? mediaItem.backdropPath : mediaItem.portraitPath
        
        if let mediaCell = cell as? TypeErasedMediaCellView {
            if let imageUrl = URL(string: imagePath) {
                Nuke.loadImage(
                    with: imageUrl,
                    options: ImageLoadingOptions(
                        transition: .fadeIn(duration: 0.3)
                    ),
                    into: mediaCell.typeErasedImageView
                )
            }
        }
        
        if let featuredCell = cell as? FeaturedCellView {
            featuredCell.titleLabel.text = mediaItem.title.uppercased()
            featuredCell.userScoreView.setColorfulValue(CGFloat(mediaItem.userScore * 10.0))
        }
        
        if indexPath.section == 0 && focusedFeaturedItemIndex == nil {
            focusedFeaturedItemIndex = 0
        }
    }
    
    func collectionView(_ collectionView: MultiCollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size: CGSize!
        if indexPath.section == 0 {
            let width = collectionView.frame.width
            let height = 9 * width / 16
            size = CGSize(width: width, height: height)
        }
        else {
          size = CGSize(width: 160, height: 240)
        }
        
        return size
    }

    func collectionView(_ collectionView: MultiCollectionView, insetForSectionAt section: Int) -> UIEdgeInsets {
        var insets: UIEdgeInsets!
        if section == 0 {
            insets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        else if section == mediaCategories.count - 1 {
            insets = UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 20)
        }
        else {
            insets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        }
        
        return insets
    }
    
    func collectionView(_ collectionView: MultiCollectionView, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return section == 0 ? 0 : 20
    }
    
    func collectionView(_ collectionView: MultiCollectionView, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch section {
        case 0:
            return .zero
        case 1:
            return CGSize(width: collectionView.frame.width, height: 55)
        default:
            return CGSize(width: collectionView.frame.width, height: 85)
        }
    }
    
    func collectionView(_ collectionView: MultiCollectionView, referenceSizeForFooterInSection section: Int) -> CGSize {
        return section == 0 ? CGSize(width: collectionView.frame.width, height: 40) : .zero
    }
    
    func collectionView(_ collectionView: MultiCollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let category = mediaCategories[indexPath.section]

        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: mediaHeaderViewId, for: indexPath) as! MediaHeaderView
            headerView.label.text = category.name
            return headerView
        case UICollectionView.elementKindSectionFooter:
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: paginationFooterViewId, for: indexPath) as! PaginationFooterView
            footerView.configurePaginationView(withNumberOfPages: category.items.count)
            footerView.paginationView.delegate = self
            return footerView
        default:
            return UICollectionReusableView()
        }
    }
    
    func collectionView(_ collectionView: MultiCollectionView, shouldEnablePagingAt section: Int) -> Bool {
        return section == 0 ? true : false
    }
    
    func collectionViewWillEndDraggingHorizontally(_ collectionView: MultiCollectionView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>, section: Int) {
        guard section == 0 else {
            return
        }
        
        focusedFeaturedItemIndex = Int(targetContentOffset.pointee.x / collectionView.frame.width)
    }
    
    func collectionView(_ collectionView: MultiCollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "movieDetails", sender: self)
    }
        
    // MARK: - ACPaginationViewDelegate -

    func paginationView(_ paginationView: ACPaginationView, didSelect index: Int) {
        collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: true)
        focusedFeaturedItemIndex = index
    }
}

