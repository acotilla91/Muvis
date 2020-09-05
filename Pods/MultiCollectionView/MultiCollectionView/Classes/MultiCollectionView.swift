//
//  MultiCollectionView.swift
//  Created by Alejandro Cotilla on 1/26/19.
//

import UIKit

@objc public protocol MultiCollectionViewDelegate: class {
    func numberOfSections(in collectionView: MultiCollectionView) -> Int
    func collectionView(_ collectionView: MultiCollectionView, numberOfItemsInSection section: Int) -> Int
    func collectionView(_ collectionView: MultiCollectionView, reuseIdentifierForCellAt indexPath: IndexPath) -> String
    func collectionView(_ collectionView: MultiCollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
    @objc optional func collectionView(_ collectionView: MultiCollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize
    @objc optional func collectionView(_ collectionView: MultiCollectionView, insetForSectionAt section: Int) -> UIEdgeInsets
    @objc optional func collectionView(_ collectionView: MultiCollectionView, minimumLineSpacingForSectionAt section: Int) -> CGFloat
    @objc optional func collectionView(_ collectionView: MultiCollectionView, referenceSizeForHeaderInSection section: Int) -> CGSize
    @objc optional func collectionView(_ collectionView: MultiCollectionView, referenceSizeForFooterInSection section: Int) -> CGSize
    @objc optional func collectionView(_ collectionView: MultiCollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView
    @objc optional func collectionView(_ collectionView: MultiCollectionView, didSelectItemAt indexPath: IndexPath)
    
    #if os(iOS)
    @objc optional func collectionView(_ collectionView: MultiCollectionView, shouldEnablePagingAt section: Int) -> Bool
    #endif
    
    @objc optional func collectionViewDidScrollHorizontally(_ collectionView: MultiCollectionView, toOffset offset: CGPoint, inSection section: Int)
    @objc optional func collectionViewDidScrollVertically(_ collectionView: MultiCollectionView, toOffset offset: CGPoint)
    
    @objc optional func collectionViewWillEndDraggingHorizontally(_ collectionView: MultiCollectionView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>, section: Int)
    @objc optional func collectionViewWillEndDraggingVertically(_ collectionView: MultiCollectionView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
}

public class MultiCollectionView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    public weak var delegate: MultiCollectionViewDelegate?
    
    private var tableCollectionView: UICollectionView!
    private let collectionViewCellIndentifier = String(describing: MultiCollectionViewCell.self)
    private var cellClassesReuseRegistry: [String: AnyClass?] = [:]
    private var cellNibsReuseRegistry: [String: UINib?] = [:]
    private var sectionsOffset: [Int: CGPoint] = [:]

    private var lastSelectedIndexPath: IndexPath?
    
    // MARK: - Init -
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        configureCollectionView()
    }
    
    private func configureCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical

        tableCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        tableCollectionView.clipsToBounds = false
        tableCollectionView.backgroundColor = .clear
        tableCollectionView.showsVerticalScrollIndicator = false
        tableCollectionView.dataSource = self
        tableCollectionView.delegate = self
        addSubview(tableCollectionView)
        
        // Setup constraints
        tableCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableCollectionView.topAnchor.constraint(equalTo: topAnchor),
            tableCollectionView.leftAnchor.constraint(equalTo: leftAnchor),
            tableCollectionView.rightAnchor.constraint(equalTo: rightAnchor),
            tableCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        tableCollectionView.register(MultiCollectionViewCell.self, forCellWithReuseIdentifier: collectionViewCellIndentifier)
    }
    
    // MARK: - UICollectionView Communication Methods -
    
    public func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        cellClassesReuseRegistry[identifier] = cellClass
    }
    
    public func register(_ nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        cellNibsReuseRegistry[identifier] = nib
    }
    
    public func register(_ viewClass: AnyClass?, forSupplementaryViewOfKind elementKind: String, withReuseIdentifier identifier: String) {
        tableCollectionView.register(viewClass, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: identifier)
    }
    
    public func register(_ nib: UINib?, forSupplementaryViewOfKind kind: String, withReuseIdentifier identifier: String) {
        tableCollectionView.register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
    }
    
    public func dequeueReusableSupplementaryView(ofKind elementKind: String, withReuseIdentifier identifier: String, for indexPath: IndexPath) -> UICollectionReusableView {
        return tableCollectionView.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: identifier, for: indexPath)
    }
    
    public func reloadData() {
        tableCollectionView.reloadData()
    }
    
    public var contentInset: UIEdgeInsets {
        set {
            tableCollectionView.contentInset = newValue
        }
        get {
            return tableCollectionView.contentInset
        }
    }
    
    public var contentOffset: CGPoint {
        set {
            tableCollectionView.contentOffset = newValue
        }
        get {
            return tableCollectionView.contentOffset
        }
    }
    
    public var contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior {
        set {
            tableCollectionView.contentInsetAdjustmentBehavior = newValue
        }
        get {
            return tableCollectionView.contentInsetAdjustmentBehavior
        }
    }
    
    public var collectionViewLayout: UICollectionViewLayout {
        set {
            tableCollectionView.collectionViewLayout = newValue
        }
        get {
            return tableCollectionView.collectionViewLayout
        }
    }
    
    public var isTracking: Bool {
        return tableCollectionView.isTracking
    }
    
    public func cellForItem(at indexPath: IndexPath) -> UICollectionViewCell? {
        guard
            let multiCollectionViewCell = tableCollectionView.cellForItem(at: IndexPath(item: 0, section: indexPath.section)) as? MultiCollectionViewCell,
            let multiCollectionViewRow = multiCollectionViewCell.collectionViewRow,
            let cell = multiCollectionViewRow.cellForItem(at: IndexPath(item: indexPath.item, section: 0))
            else {
                return nil
        }

        return cell
    }
    
    public func supplementaryView(forElementKind elementKind: String, at section: Int) -> UICollectionReusableView? {
        return tableCollectionView.supplementaryView(forElementKind: elementKind, at: IndexPath(item: 0, section: section))
    }
    
    public func scrollToItem(at indexPath: IndexPath, at scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
        // Scroll vertically
        tableCollectionView.scrollToItem(at: IndexPath(item: 0, section: indexPath.section), at: .top, animated: false)
        tableCollectionView.layoutIfNeeded()

        // Scroll horizontally
        if let multiCollectionViewCell = tableCollectionView.cellForItem(at: IndexPath(item: 0, section: indexPath.section)) as? MultiCollectionViewCell {
            multiCollectionViewCell.collectionViewRow.scrollToItem(at: IndexPath(item: indexPath.item, section: 0), at: scrollPosition, animated: animated)
        }
    }
    
    public func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        tableCollectionView.setContentOffset(contentOffset, animated: true)
    }
    
    public var indexPathsForSelectedItems: [IndexPath]? {
        guard let indexPath = lastSelectedIndexPath else {
            return nil
        }
        return [indexPath]
    }
    
    // MARK: - Collection View Callbacks -
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == tableCollectionView {
            return delegate?.numberOfSections(in: self) ?? 0
        }
        
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == tableCollectionView {
            // Only supporting one row per section
            return 1
        }

        let collectionViewRow = collectionView as! MultiCollectionViewRow
        return delegate?.collectionView(self, numberOfItemsInSection: collectionViewRow.section) ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Configure collection view row cells (this collection cells)
        if collectionView == tableCollectionView {
            let multiCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionViewCellIndentifier, for: indexPath) as! MultiCollectionViewCell
            multiCollectionViewCell.configure(with: cellClassesReuseRegistry, nibsReuseRegistry: cellNibsReuseRegistry, listener: self)
            multiCollectionViewCell.section = indexPath.section
            
            // Get saved offset before resetting it
            let savedOffset = sectionsOffset[indexPath.section]
            
            // Reset content offset to avoid issues when reloading data
            multiCollectionViewCell.collectionViewRow.setContentOffset(.zero, animated: false)
            
            // Ask delegate for paging configuration
            #if os(iOS)
            let pagingEnabled = delegate?.collectionView?(self, shouldEnablePagingAt: indexPath.section) ?? false
            multiCollectionViewCell.collectionViewRow.isPagingEnabled = pagingEnabled
            #endif
            
            // Apply saved offset
            if let offset = savedOffset {
                multiCollectionViewCell.collectionViewRow.setContentOffset(offset, animated: false)
            }
            
            // Disable scrolling until the cell appears
            multiCollectionViewCell.collectionViewRow.isScrollEnabled = false
            
            // Ensure the proper cells are drawn after the reuse
            multiCollectionViewCell.collectionViewRow.reloadData()
            
            return multiCollectionViewCell
        }
        
        let collectionViewRow = collectionView as! MultiCollectionViewRow
        let collectionViewRowItemIndex = IndexPath(item: indexPath.item, section: collectionViewRow.section)
        
        if let cellIdentifier = delegate?.collectionView(self, reuseIdentifierForCellAt: collectionViewRowItemIndex) {
            let cell = collectionViewRow.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: collectionViewRowItemIndex)
            delegate?.collectionView(self, willDisplay: cell, forItemAt: collectionViewRowItemIndex)
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let multiCollectionViewCell = cell as? MultiCollectionViewCell {
            // Re-allow scrolling now that the cell is about to appear
            multiCollectionViewCell.collectionViewRow.isScrollEnabled = true
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize

        if collectionView == tableCollectionView {
            size.width = tableCollectionView.frame.width
            if let contentCellSize = delegate?.collectionView?(self, sizeForItemAt: IndexPath(item: 0, section: indexPath.section)) {
                size.height = contentCellSize.height
            }
        }
        else {
            let collectionViewRow = collectionView as! MultiCollectionViewRow
            if let contentCellSize = delegate?.collectionView?(self, sizeForItemAt: IndexPath(item: indexPath.item, section: collectionViewRow.section)) {
                size = contentCellSize
            }
        }
        
        return size
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {

        var insets: UIEdgeInsets = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).sectionInset
        let actualSection = collectionView == tableCollectionView ? section : (collectionView as! MultiCollectionViewRow).section
        if let clientInsets = delegate?.collectionView?(self, insetForSectionAt: actualSection) {
            if collectionView == tableCollectionView {
                insets.top = clientInsets.top
                insets.bottom = clientInsets.bottom
            }
            else {
                insets.left = clientInsets.left
                insets.right = clientInsets.right
            }
        }

        return insets
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        var spacing = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing
        if
            let collectionViewRow = collectionView as? MultiCollectionViewRow,
            let minimumSpacing = delegate?.collectionView?(self, minimumLineSpacingForSectionAt: collectionViewRow.section) {
            spacing = minimumSpacing
        }
        
        return spacing
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if
            collectionView == tableCollectionView,
            let size = delegate?.collectionView?(self, referenceSizeForHeaderInSection: section) {
            return size
        }
        
        return .zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if
            collectionView == tableCollectionView,
            let size = delegate?.collectionView?(self, referenceSizeForFooterInSection: section) {
            return size
        }
        
        return .zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let view = delegate?.collectionView?(self, viewForSupplementaryElementOfKind: kind, at: indexPath) else {
            fatalError("Unavailable view for supplementary element after specifying a size for the element.")
        }
  
        return view
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView != tableCollectionView {
            let collectionViewRow = collectionView as! MultiCollectionViewRow
            lastSelectedIndexPath = IndexPath(item: indexPath.item, section: collectionViewRow.section)
            delegate?.collectionView?(self, didSelectItemAt: IndexPath(item: indexPath.item, section: collectionViewRow.section))
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        lastSelectedIndexPath = nil
    }
    
    public func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        // Forward focus to the actual cells
        return collectionView != self.tableCollectionView
    }
    
    // MARK: - UIScrollViewDelegate -

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let direction: UICollectionView.ScrollDirection = scrollView == tableCollectionView ? .vertical : .horizontal
        
        if direction == .horizontal {
            let collectionViewRow = scrollView as! MultiCollectionViewRow
            let savedOffset = sectionsOffset[collectionViewRow.section] ?? .zero
            
            if collectionViewRow.isScrollEnabled {
                // Save offset to restore it once the cell gets reused
                sectionsOffset[collectionViewRow.section] = collectionViewRow.contentOffset
            }
            else if !collectionViewRow.contentOffset.equalTo(savedOffset) {
                // Reject new content offset and restore previous one if content offset changes are not allowed.
                collectionViewRow.contentOffset = savedOffset
            }
        }
        
        // Notify delegate
        if let collectionViewRow = scrollView as? MultiCollectionViewRow {
            delegate?.collectionViewDidScrollHorizontally?(self, toOffset: scrollView.contentOffset, inSection: collectionViewRow.section)
        }
        else {
            delegate?.collectionViewDidScrollVertically?(self, toOffset: scrollView.contentOffset)
        }
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if let collectionViewRow = scrollView as? MultiCollectionViewRow {
            delegate?.collectionViewWillEndDraggingHorizontally?(self, withVelocity: velocity, targetContentOffset: targetContentOffset, section: collectionViewRow.section)
        }
        else {
            delegate?.collectionViewWillEndDraggingVertically?(self, withVelocity: velocity, targetContentOffset: targetContentOffset)
        }
    }
}
