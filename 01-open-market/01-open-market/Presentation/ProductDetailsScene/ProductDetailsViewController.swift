//
//  ProductDetailsViewController.swift
//  01-open-market
//
//  Copyright (c) 2023 Jeremy All rights reserved.


import UIKit
import RxSwift

final class ProductDetailsViewController: UIViewController {
    enum Style {
        case post
        case edit
    }
    
    // MARK: View(s)
    private let imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }()
    
    private let productImagesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let productNameView: NameableTextFieldView = {
        let nameableTextView = NameableTextFieldView(name: "Name", placeHolder: "상품 이름")
        return nameableTextView
    }()
    private let priceNameView: NameableTextFieldView = {
        let nameableTextView = NameableTextFieldView(name: "Price", placeHolder: "상품 가격")
        return nameableTextView
    }()
    private let discountNameView: NameableTextFieldView = {
        let nameableTextView = NameableTextFieldView(name: "Discount", placeHolder: "상품 할인 가격")
        return nameableTextView
    }()
    private let stockNameView: NameableTextFieldView = {
        let nameableTextView = NameableTextFieldView(name: "Stock", placeHolder: "상품 재고 수량")
        return nameableTextView
    }()
    
    private let currencySelectorView: UISegmentedControl = {
        let segmentControl = UISegmentedControl(items: ["KRW", "USD"])
        segmentControl.selectedSegmentIndex = 0
        segmentControl.isEnabled = false
        return segmentControl
    }()
    
    private let priceStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillProportionally
        stack.alignment = .fill
        return stack
    }()
    private let detailDataStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.layoutMargins = UIEdgeInsets(
            top: 20,
            left: 20,
            bottom: 20,
            right: 20
        )
        stack.spacing = 10
        stack.isLayoutMarginsRelativeArrangement = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    private let productDescriptionTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .systemGreen
        textView.font = UIFont(name: "ArialHebrew", size: 20)
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private let disposeBag = DisposeBag()
    private var selectedImages: [UIImage] = []
    var viewModel: ProductDetailsViewModel?
    
    // MARK: Override(s)
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = .systemGray6
        combineViews()
        configureViewConstraints()
        configureNavigationItems()
        configureInitialProductEditability()
        bindViewModel()
        productImagesCollectionView.register(
            ProductImageCell.self,
            forCellWithReuseIdentifier: "cell"
        )
        productImagesCollectionView.delegate = self
        productImagesCollectionView.dataSource = self
        imagePicker.delegate = self
    }
    
    // MARK: Private Function(s)
    
    private func configureInitialProductEditability() {
        guard let viewModel = viewModel else { return }
        
        switch viewModel.presentingStyle {
        case .edit(_):
            configureProductEditMode(isEditable: false)
        case .post:
            configureProductEditMode(isEditable: true)
        }
    }
    
    private func bindViewModel() {
        guard let viewModel = viewModel else { return }
        
        let initialSetUpTrigger = self.rx.methodInvoked(#selector(viewDidLoad))
            .map { _ in}
            .asObservable()
        
        let doneTrigger = self.rx.methodInvoked(#selector(didTapDoneButton))
            .map { _ in }
            .asObservable()
        let editTrigger = self.rx.methodInvoked(#selector(didTapEditButton))
            .map { _ in }
            .asObservable()
        
        let output = viewModel.transform(
            input: .init(
                initialSetUpTrigger: initialSetUpTrigger,
                doneTrigger: doneTrigger,
                editTrigger: editTrigger
            )
        )
        
        output.initialSetUpResponse
            .filter { $0 != nil }
            .subscribe(onNext: { [weak self] data in
                self?.setString(data: data)
            })
            .disposed(by: disposeBag)
        
        output.doneResponse
            .subscribe(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func setString(data: PostProduct?) {
        guard let data = data else { return }
        productNameView.text = data.name
        priceNameView.text = data.price.description
        discountNameView.text = data.discount.description
        stockNameView.text = data.stock.description
        productDescriptionTextView.text = data.description
        
        switch data.currency {
        case .KRW:
            currencySelectorView.selectedSegmentIndex = 0
        case .USD:
            currencySelectorView.selectedSegmentIndex = 1
        }
    }
    
    private func configureProductEditMode(isEditable: Bool) {
        productNameView.isEditable = isEditable
        priceNameView.isEditable = isEditable
        discountNameView.isEditable = isEditable
        stockNameView.isEditable = isEditable
        currencySelectorView.isEnabled = isEditable
        productDescriptionTextView.isEditable = isEditable
    }
    
    private func createDoneButton() -> UIBarButtonItem {
        return UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(didTapDoneButton)
        )
    }
    
    @objc
    private func didTapDoneButton() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc
    private func didTapEditButton() {
        configureProductEditMode(isEditable: true)
        navigationItem.rightBarButtonItem = createDoneButton()
    }
    
    private func configureNavigationItems() {
        guard let viewModel = viewModel else { return }
        let editButton = UIBarButtonItem(
            barButtonSystemItem: .edit,
            target: self,
            action: #selector(didTapEditButton)
        )
        switch viewModel.presentingStyle {
        case .edit(product: let product):
            navigationItem.title = product.name
            navigationItem.rightBarButtonItem = editButton
        case .post:
            let doneButton = createDoneButton()
            doneButton.isEnabled = false
            navigationItem.rightBarButtonItem = doneButton
        }
    }
    
    private func combineViews() {
        let productPriceViews: [UIView] = [
            priceNameView,
            currencySelectorView,
        ]
        let productDetailsViews: [UIView] = [
            productNameView,
            priceStackView,
            discountNameView,
            stockNameView
        ]
        priceStackView.addMultipleArrangedSubviews(productPriceViews)
        detailDataStackView.addMultipleArrangedSubviews(productDetailsViews)
        view.addSubview(productImagesCollectionView)
        view.addSubview(detailDataStackView)
        view.addSubview(productDescriptionTextView)
    }
    
    private func configureViewConstraints() {
        
        NSLayoutConstraint.activate([
            productImagesCollectionView.topAnchor
                .constraint(
                    equalTo: view.safeAreaLayoutGuide.topAnchor
                ),
            productImagesCollectionView.heightAnchor
                .constraint(
                    equalTo: view.heightAnchor,
                    multiplier: 0.2
                ),
            productImagesCollectionView.widthAnchor
                .constraint(
                    equalTo: view.widthAnchor
                ),
        ])
        
        NSLayoutConstraint.activate([
            detailDataStackView.topAnchor
                .constraint(
                    equalTo: productImagesCollectionView.bottomAnchor
                ),
            detailDataStackView.heightAnchor
                .constraint(
                    equalTo: view.heightAnchor,
                    multiplier: 0.25
                ),
            detailDataStackView.widthAnchor
                .constraint(
                    equalTo: view.widthAnchor
                ),
        ])
        
        NSLayoutConstraint.activate([
            productDescriptionTextView.topAnchor
                .constraint(
                    equalTo: detailDataStackView.bottomAnchor
                ),
            productDescriptionTextView.widthAnchor
                .constraint(
                    equalTo: view.widthAnchor
                ),
            productDescriptionTextView.bottomAnchor
                .constraint(
                    greaterThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor
                ),
        ])
        
        NSLayoutConstraint.activate([
            priceNameView.trailingAnchor
                .constraint(
                    equalTo: currencySelectorView.leadingAnchor,
                    constant: -10
                ),
            currencySelectorView.leadingAnchor
                .constraint(
                    equalTo: priceNameView.trailingAnchor,
                    constant: 20
                ),
            currencySelectorView.topAnchor
                .constraint(
                    equalTo: priceStackView.topAnchor
                ),
            currencySelectorView.trailingAnchor
                .constraint(
                    equalTo: priceStackView.trailingAnchor
                ),
            currencySelectorView.bottomAnchor
                .constraint(
                    equalTo: priceStackView.bottomAnchor
                ),
            currencySelectorView.widthAnchor
                .constraint(
                    equalTo: priceStackView.widthAnchor,
                    multiplier: 0.25
                ),
        ])
    }
}

extension ProductDetailsViewController: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return 1 + selectedImages.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "cell",
            for: indexPath
        ) as? ProductImageCell else {
            return UICollectionViewCell()
        }
        
        if indexPath.item == 0 {
            cell.backgroundColor = .systemGray4
            cell.tintColor = .systemPurple
            let addImage = UIImage(named: "plusImage")
            cell.imageView.image = addImage
            return cell
        }
        
        cell.backgroundColor = .systemGray5
        cell.imageView.image = selectedImages[indexPath.item - 1]
        
        return cell
    }
}

extension ProductDetailsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            present(imagePicker, animated: true)
        }
    }
}

extension ProductDetailsViewController: UIImagePickerControllerDelegate,
                                            UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            selectedImages.append(editedImage)
            viewModel?.images.append(editedImage)
            productImagesCollectionView.reloadData()
        }
        
        picker.dismiss(animated: true)
    }
}

extension ProductDetailsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width: CGFloat = view.bounds.width * 0.3
        let height: CGFloat = width
        
        return CGSize(width: width, height: height)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return UIEdgeInsets(
            top: 10,
            left: 10,
            bottom: 10,
            right: 10
        )
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 12
    }
}
